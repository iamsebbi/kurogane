import fs from 'fs';
import path from 'path';
import {
  WatchOrderPreset,
  WatchOrderPresetItem,
  WatchOrderVoteResult,
  WatchOrderPresetStatus,
  MediaItem,
} from '@kurogane/shared';
import { supabase, isSupabaseConfigured } from './supabase';
import { dbService } from './db';
import { sanitizeRoot } from './franchise';
import { persistentDb } from './db-persistent';

const DATA_DIR = path.join(__dirname, '../../data');
const PRESETS_FILE = path.join(DATA_DIR, 'watch-order-presets-db.json');

// Praguri configurabile din variabile de mediu
const VERIFY_THRESHOLD_VOTES = parseInt(process.env.WATCH_ORDER_VERIFY_THRESHOLD_VOTES || '15', 10);
const VERIFY_MIN_RATIO = parseFloat(process.env.WATCH_ORDER_VERIFY_MIN_RATIO || '0.75');
const DEMOTE_RATIO = parseFloat(process.env.WATCH_ORDER_DEMOTE_RATIO || '0.50');
const REPORT_FLAG_THRESHOLD = parseInt(process.env.WATCH_ORDER_REPORT_FLAG_THRESHOLD || '5', 10);

interface LocalVoteRecord {
  presetId: string;
  userId: string;
  vote: number;
  votedAt: string;
}

interface LocalReportRecord {
  presetId: string;
  userId: string;
  reason: string;
  createdAt: string;
}

interface LocalPresetStore {
  presets: WatchOrderPreset[];
  votes: LocalVoteRecord[];
  reports: LocalReportRecord[];
}

export class WatchOrderPresetService {
  private localStore: LocalPresetStore = {
    presets: [],
    votes: [],
    reports: [],
  };

  private presetMutex: Map<string, Promise<any>> = new Map();

  constructor() {
    this.initLocalStore();
  }

  private initLocalStore(): void {
    try {
      if (!fs.existsSync(DATA_DIR)) {
        fs.mkdirSync(DATA_DIR, { recursive: true });
      }
      if (fs.existsSync(PRESETS_FILE)) {
        const raw = fs.readFileSync(PRESETS_FILE, 'utf-8');
        this.localStore = JSON.parse(raw);
      } else {
        this.saveLocalStore();
      }
    } catch (err) {
      console.warn('⚠️ [WatchOrderPresetService] Error loading local presets store:', err);
    }
  }

  private saveLocalStore(): void {
    try {
      fs.writeFileSync(PRESETS_FILE, JSON.stringify(this.localStore, null, 2), 'utf-8');
    } catch (err) {
      console.error('❌ [WatchOrderPresetService] Error saving local presets store:', err);
    }
  }

  /**
   * Determină identificatorul canonic al francizei pentru orice serie
   */
  public getCanonicalFranchiseId(item: MediaItem): string {
    if (item.franchiseId && item.franchiseId.trim().length > 0) {
      return item.franchiseId.trim();
    }
    const title = item.title.userPreferred || item.title.romaji || item.title.english || '';
    return sanitizeRoot(title);
  }

  /**
   * Returnează toate producțiile canonice ale unei francize din baza de date
   */
  public getFranchiseCanonicalMediaItems(franchiseRoot: string): MediaItem[] {
    const all = dbService.getAllOfflineMedia();
    return all.filter((m) => {
      const mRoot = this.getCanonicalFranchiseId(m);
      return mRoot.length >= 3 && (mRoot === franchiseRoot || mRoot.includes(franchiseRoot) || franchiseRoot.includes(mRoot));
    });
  }

  /**
   * Preia preset-urile active pentru o franciză dată, atașând votul userului și flag-ul de staleness
   */
  public async getPresetsForFranchise(franchiseRoot: string, currentUserId?: string): Promise<WatchOrderPreset[]> {
    const canonicalItems = this.getFranchiseCanonicalMediaItems(franchiseRoot);
    const canonicalCount = canonicalItems.length;

    // 1. Supabase Mode
    if (isSupabaseConfigured && supabase) {
      try {
        const { data: presetsData, error: presetsErr } = await supabase
          .from('watch_order_presets')
          .select(`
            id,
            franchise_root,
            title,
            description,
            submitted_by,
            status,
            upvotes,
            downvotes,
            report_count,
            is_selective_curated,
            created_at,
            updated_at,
            users:submitted_by (username, avatar_url)
          `)
          .eq('franchise_root', franchiseRoot)
          .in('status', ['community_verified', 'pending_review'])
          .order('upvotes', { ascending: false });

        if (presetsErr) throw presetsErr;

        if (!presetsData || presetsData.length === 0) {
          return [];
        }

        const presetIds = presetsData.map((p) => p.id);

        // Preia elementele fiecărui preset
        const { data: itemsData, error: itemsErr } = await supabase
          .from('watch_order_preset_items')
          .select('id, preset_id, media_id, position, is_canon, note')
          .in('preset_id', presetIds)
          .order('position', { ascending: true });

        if (itemsErr) throw itemsErr;

        // Preia votul utilizatorului curent dacă este logat
        let userVotesMap: Record<string, number> = {};
        if (currentUserId) {
          const { data: votesData } = await supabase
            .from('watch_order_preset_votes')
            .select('preset_id, vote')
            .eq('user_id', currentUserId)
            .in('preset_id', presetIds);

          if (votesData) {
            userVotesMap = votesData.reduce((acc: any, v: any) => {
              acc[v.preset_id] = v.vote;
              return acc;
            }, {});
          }
        }

        return presetsData.map((p: any) => {
          const items: WatchOrderPresetItem[] = (itemsData || [])
            .filter((it: any) => it.preset_id === p.id)
            .map((it: any) => {
              const fullMedia = dbService.getMediaById(it.media_id);
              return {
                id: it.id,
                presetId: it.preset_id,
                mediaId: it.media_id,
                position: it.position,
                isCanon: it.is_canon,
                note: it.note,
                mediaItem: fullMedia ? {
                  id: fullMedia.id,
                  title: fullMedia.title,
                  coverImage: fullMedia.coverImage,
                  format: fullMedia.format,
                  episodes: fullMedia.episodes,
                  year: fullMedia.year,
                } : undefined,
              };
            });

          const isOutdated = canonicalCount > items.length && !p.is_selective_curated;
          const missingCount = isOutdated ? canonicalCount - items.length : 0;
          const presentMediaIds = new Set(items.map((it) => it.mediaId));
          const missingTitles = isOutdated
            ? canonicalItems
                .filter((c) => !presentMediaIds.has(c.id))
                .slice(0, 3)
                .map((c) => c.title.userPreferred)
            : [];

          return {
            id: p.id,
            franchiseRoot: p.franchise_root,
            title: p.title,
            description: p.description || undefined,
            submittedBy: p.submitted_by || null,
            submitterUsername: p.users?.username || (p.submitted_by ? 'Utilizator' : 'Utilizator șters'),
            submitterAvatarUrl: p.users?.avatar_url || undefined,
            status: p.status as WatchOrderPresetStatus,
            upvotes: p.upvotes || 0,
            downvotes: p.downvotes || 0,
            reportCount: p.report_count || 0,
            isSelectiveCurated: Boolean(p.is_selective_curated),
            isPossiblyOutdated: isOutdated,
            missingItemsCount: missingCount,
            missingTitles,
            userVote: userVotesMap[p.id] ?? null,
            items,
            createdAt: p.created_at,
            updatedAt: p.updated_at,
          };
        });
      } catch (err) {
        console.warn('⚠️ [WatchOrderPresetService] Supabase query failed, using local fallback:', err);
      }
    }

    // 2. Local Fallback Mode
    const activePresets = this.localStore.presets.filter(
      (p) => p.franchiseRoot === franchiseRoot && (p.status === 'community_verified' || p.status === 'pending_review')
    );

    return activePresets.map((p) => {
      const userVote = currentUserId
        ? this.localStore.votes.find((v) => v.presetId === p.id && v.userId === currentUserId)?.vote ?? null
        : null;

      const isOutdated = canonicalCount > p.items.length && !p.isSelectiveCurated;
      const missingCount = isOutdated ? canonicalCount - p.items.length : 0;
      const presentMediaIds = new Set(p.items.map((it) => it.mediaId));
      const missingTitles = isOutdated
        ? canonicalItems
            .filter((c) => !presentMediaIds.has(c.id))
            .slice(0, 3)
            .map((c) => c.title.userPreferred)
        : [];

      // Atașează detalii complete din offline DB
      const enrichedItems = p.items.map((it) => {
        const full = dbService.getMediaById(it.mediaId);
        return {
          ...it,
          mediaItem: full ? {
            id: full.id,
            title: full.title,
            coverImage: full.coverImage,
            format: full.format,
            episodes: full.episodes,
            year: full.year,
          } : undefined,
        };
      });

      return {
        ...p,
        userVote,
        items: enrichedItems,
        isPossiblyOutdated: isOutdated,
        missingItemsCount: missingCount,
        missingTitles,
      };
    });
  }

  /**
   * Creează o nouă propunere de preset
   */
  public async createPreset(
    userId: string,
    targetMediaId: string,
    payload: {
      title: string;
      description?: string;
      isSelectiveCurated?: boolean;
      items: { mediaId: string; position: number; isCanon?: boolean; note?: string }[];
    }
  ): Promise<WatchOrderPreset> {
    const targetMedia = dbService.getMediaById(targetMediaId);
    if (!targetMedia) {
      throw new Error(`Titlul cu id "${targetMediaId}" nu a fost găsit.`);
    }

    const franchiseRoot = this.getCanonicalFranchiseId(targetMedia);
    if (!franchiseRoot || franchiseRoot.length < 3) {
      throw new Error('Nu s-a putut deduce o franciză validă pentru această serie.');
    }

    // Validare integritate elemente
    if (!payload.items || payload.items.length < 2) {
      throw new Error('O ordine de vizionare trebuie să conțină cel puțin 2 titluri din franciză.');
    }

    // Validare unicitate poziții și media IDs
    const positions = new Set<number>();
    const mediaIds = new Set<string>();
    for (const item of payload.items) {
      if (item.position < 1) {
        throw new Error('Pozițiile elementelor trebuie să fie numere întregi >= 1.');
      }
      if (positions.has(item.position)) {
        throw new Error(`Poziția duplicată ${item.position} detectată.`);
      }
      if (mediaIds.has(item.mediaId)) {
        throw new Error(`Titlul duplicat ${item.mediaId} detectat în același preset.`);
      }
      positions.add(item.position);
      mediaIds.add(item.mediaId);
    }

    // Preluare profil autor
    const userProfile = persistentDb.getUserById(userId);
    const username = userProfile?.username || 'Utilizator';
    const avatarUrl = userProfile?.avatarUrl;

    const presetId = `preset-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;
    const now = new Date().toISOString();

    const formattedItems: WatchOrderPresetItem[] = payload.items
      .sort((a, b) => a.position - b.position)
      .map((it, idx) => ({
        id: `item-${presetId}-${idx + 1}`,
        presetId,
        mediaId: it.mediaId,
        position: it.position,
        isCanon: it.isCanon ?? true,
        note: it.note?.trim() || undefined,
      }));

    const newPreset: WatchOrderPreset = {
      id: presetId,
      franchiseRoot,
      title: payload.title.trim(),
      description: payload.description?.trim() || undefined,
      submittedBy: userId,
      submitterUsername: username,
      submitterAvatarUrl: avatarUrl,
      status: 'pending_review',
      upvotes: 0,
      downvotes: 0,
      reportCount: 0,
      isSelectiveCurated: Boolean(payload.isSelectiveCurated),
      items: formattedItems,
      createdAt: now,
      updatedAt: now,
    };

    // 1. Supabase Mode
    if (isSupabaseConfigured && supabase) {
      try {
        // Verificare rate limit (max 1 preset activ per franciză per user)
        const { data: existingActive } = await supabase
          .from('watch_order_presets')
          .select('id')
          .eq('franchise_root', franchiseRoot)
          .eq('submitted_by', userId)
          .in('status', ['pending_review', 'community_verified', 'flagged'])
          .limit(1);

        if (existingActive && existingActive.length > 0) {
          throw new Error('Ai deja o propunere activă pentru această franciză.');
        }

        const { data: insertedPreset, error: pErr } = await supabase
          .from('watch_order_presets')
          .insert({
            franchise_root: franchiseRoot,
            title: newPreset.title,
            description: newPreset.description,
            submitted_by: userId,
            status: 'pending_review',
            is_selective_curated: newPreset.isSelectiveCurated,
          })
          .select()
          .single();

        if (pErr) throw pErr;

        const dbPresetId = insertedPreset.id;
        const dbItems = formattedItems.map((it) => ({
          preset_id: dbPresetId,
          media_id: it.mediaId,
          position: it.position,
          is_canon: it.isCanon,
          note: it.note,
        }));

        const { error: iErr } = await supabase.from('watch_order_preset_items').insert(dbItems);
        if (iErr) throw iErr;

        newPreset.id = dbPresetId;
        return newPreset;
      } catch (err: any) {
        console.warn('⚠️ [WatchOrderPresetService] Supabase insert failed, saving locally:', err.message);
        if (err.message.includes('Ai deja o propunere')) {
          throw err;
        }
      }
    }

    // 2. Local Fallback Mode
    const existingActiveLocal = this.localStore.presets.find(
      (p) =>
        p.franchiseRoot === franchiseRoot &&
        p.submittedBy === userId &&
        ['pending_review', 'community_verified', 'flagged'].includes(p.status)
    );

    if (existingActiveLocal) {
      throw new Error('Ai deja o propunere activă pentru această franciză.');
    }

    this.localStore.presets.push(newPreset);
    this.saveLocalStore();
    return newPreset;
  }

  /**
   * Votează un preset (+1 sau -1) atomic cu Row Locking
   */
  public async votePreset(userId: string, presetId: string, vote: 1 | -1): Promise<WatchOrderVoteResult> {
    // 1. Supabase Mode (RPC atomic cu SELECT ... FOR UPDATE)
    if (isSupabaseConfigured && supabase) {
      try {
        const { data, error } = await supabase.rpc('rpc_vote_watch_order_preset', {
          p_preset_id: presetId,
          p_user_id: userId,
          p_vote: vote,
          p_threshold_votes: VERIFY_THRESHOLD_VOTES,
          p_verify_ratio: VERIFY_MIN_RATIO,
          p_demote_ratio: DEMOTE_RATIO,
        });

        if (error) {
          if (error.code === '42501' || error.message.includes('propria ta propunere')) {
            throw new Error('Nu poți vota propria ta propunere.');
          }
          throw error;
        }

        return {
          success: true,
          upvotes: data.upvotes,
          downvotes: data.downvotes,
          status: data.status,
          ratio: data.ratio,
          userVote: vote,
        };
      } catch (err: any) {
        console.warn('⚠️ [WatchOrderPresetService] Supabase RPC failed, using local mutex fallback:', err.message);
        if (err.message.includes('propria ta propunere')) {
          throw err;
        }
      }
    }

    // 2. Local Fallback Mode cu Mutex per preset (Zero Race Conditions în memorie)
    const currentPromise = (this.presetMutex.get(presetId) || Promise.resolve()).catch(() => {});
    const nextPromise = currentPromise.then(() => this.executeLocalVote(userId, presetId, vote));
    this.presetMutex.set(presetId, nextPromise.catch(() => {}));
    return nextPromise;
  }

  private executeLocalVote(userId: string, presetId: string, vote: 1 | -1): WatchOrderVoteResult {
    const preset = this.localStore.presets.find((p) => p.id === presetId);
    if (!preset) {
      throw new Error(`Preset-ul cu ID ${presetId} nu există.`);
    }

    // Anti-Self-Vote
    if (preset.submittedBy === userId) {
      throw new Error('Nu poți vota propria ta propunere.');
    }

    // Upsert vote
    const existingIdx = this.localStore.votes.findIndex((v) => v.presetId === presetId && v.userId === userId);
    if (existingIdx >= 0) {
      this.localStore.votes[existingIdx].vote = vote;
      this.localStore.votes[existingIdx].votedAt = new Date().toISOString();
    } else {
      this.localStore.votes.push({
        presetId,
        userId,
        vote,
        votedAt: new Date().toISOString(),
      });
    }

    // Recalculare
    const presetVotes = this.localStore.votes.filter((v) => v.presetId === presetId);
    const upvotes = presetVotes.filter((v) => v.vote === 1).length;
    const downvotes = presetVotes.filter((v) => v.vote === -1).length;
    const total = upvotes + downvotes;
    const ratio = total > 0 ? upvotes / total : 0;

    // State machine
    if (!['flagged', 'rejected', 'draft'].includes(preset.status)) {
      if (preset.status === 'pending_review' && upvotes >= VERIFY_THRESHOLD_VOTES && ratio >= VERIFY_MIN_RATIO) {
        preset.status = 'community_verified';
      } else if (
        preset.status === 'community_verified' &&
        (ratio < DEMOTE_RATIO || upvotes - downvotes < 5)
      ) {
        preset.status = 'pending_review';
      }
    }

    preset.upvotes = upvotes;
    preset.downvotes = downvotes;
    preset.updatedAt = new Date().toISOString();

    this.saveLocalStore();

    return {
      success: true,
      upvotes,
      downvotes,
      status: preset.status,
      ratio: Math.round(ratio * 100) / 100,
      userVote: vote,
    };
  }

  /**
   * Raportează un preset pentru conținut malițios sau abuz
   */
  public async reportPreset(userId: string, presetId: string, reason: string): Promise<{ success: boolean; reportCount: number; status: string }> {
    // 1. Supabase Mode (RPC atomic)
    if (isSupabaseConfigured && supabase) {
      try {
        const { data, error } = await supabase.rpc('rpc_report_watch_order_preset', {
          p_preset_id: presetId,
          p_user_id: userId,
          p_reason: reason,
          p_flag_threshold: REPORT_FLAG_THRESHOLD,
        });

        if (error) throw error;
        return {
          success: true,
          reportCount: data.report_count,
          status: data.status,
        };
      } catch (err: any) {
        console.warn('⚠️ [WatchOrderPresetService] Supabase report RPC failed, using local fallback:', err.message);
      }
    }

    // 2. Local Fallback Mode
    const preset = this.localStore.presets.find((p) => p.id === presetId);
    if (!preset) {
      throw new Error(`Preset-ul cu ID ${presetId} nu există.`);
    }

    const alreadyReported = this.localStore.reports.some((r) => r.presetId === presetId && r.userId === userId);
    if (!alreadyReported) {
      this.localStore.reports.push({
        presetId,
        userId,
        reason,
        createdAt: new Date().toISOString(),
      });
    }

    const reportCount = this.localStore.reports.filter((r) => r.presetId === presetId).length;
    if (reportCount >= REPORT_FLAG_THRESHOLD && preset.status !== 'rejected') {
      preset.status = 'flagged';
    }

    preset.reportCount = reportCount;
    preset.updatedAt = new Date().toISOString();
    this.saveLocalStore();

    return {
      success: true,
      reportCount,
      status: preset.status,
    };
  }

  /**
   * Acțiune administrativă de moderare (Admin Only)
   */
  public async moderatePreset(presetId: string, action: 'approve' | 'reject' | 'reopen'): Promise<{ success: boolean; status: string }> {
    let newStatus: WatchOrderPresetStatus = 'pending_review';
    if (action === 'approve') newStatus = 'community_verified';
    if (action === 'reject') newStatus = 'rejected';
    if (action === 'reopen') newStatus = 'pending_review';

    if (isSupabaseConfigured && supabase) {
      await supabase
        .from('watch_order_presets')
        .update({ status: newStatus, updated_at: new Date().toISOString() })
        .eq('id', presetId);
    }

    const localPreset = this.localStore.presets.find((p) => p.id === presetId);
    if (localPreset) {
      localPreset.status = newStatus;
      localPreset.updatedAt = new Date().toISOString();
      this.saveLocalStore();
    }

    return { success: true, status: newStatus };
  }
}

export const watchOrderPresetService = new WatchOrderPresetService();
