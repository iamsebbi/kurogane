import { Bindings } from '../types';
import { getMediaById } from './anilist';

export function sanitizeRoot(title: string): string {
  if (!title) return '';
  return title
    .toLowerCase()
    .replace(/:\s*(season|part|cour)\s*\d+/gi, '')
    .replace(/\s+\d+(st|nd|rd|th)?\s+(season|part|cour)/gi, '')
    .replace(/\s+(season|part|cour)\s+\d+/gi, '')
    .replace(/[:\-].*$/, '')
    .replace(/[^a-z0-9]/gi, '');
}

const FRANCHISE_GUIDES: Record<string, any> = {
  'naruto-series': {
    franchiseId: 'naruto-series',
    franchiseName: 'Universul Naruto',
    description: 'Calea Ninja a lui Naruto Uzumaki către titlul de Hokage și generația lui Boruto.',
    communityTip: '✨ Ghid Naruto: Ordinea canonică este Naruto (Ep. 1-220) ➔ Naruto Shippuuden (Ep. 1-500) ➔ The Last: Naruto the Movie (Vizionează după ep. 493 Shippuuden!) ➔ Boruto: Naruto Next Generations.',
    paths: {
      RECOMMENDED: [
        {
          id: 'naruto-original',
          mediaId: 'anilist-20',
          title: 'Naruto',
          type: 'TV',
          episodesInfo: '220 Episoade (Anii 2002–2007)',
          releaseYear: 2002,
          coverImage: 'https://cdn.myanimelist.net/images/anime/13/11403.jpg',
          orderIndex: 1,
          note: 'Partea I: Copilăria lui Naruto. Episoadele 136-219 sunt filler opțional.',
          isCanon: true,
        },
        {
          id: 'naruto-shippuuden',
          mediaId: 'anilist-1735',
          title: 'Naruto: Shippuuden',
          type: 'TV',
          episodesInfo: '500 Episoade (Anii 2007–2017)',
          releaseYear: 2007,
          coverImage: 'https://cdn.myanimelist.net/images/anime/5/17407.jpg',
          orderIndex: 2,
          note: 'Partea II: Naruto la adolescență și Marele Război Shinobi.',
          isCanon: true,
        },
        {
          id: 'naruto-the-last',
          mediaId: 'anilist-20596',
          title: 'The Last: Naruto the Movie',
          type: 'MOVIE',
          episodesInfo: '1 Film (112 min)',
          releaseYear: 2014,
          coverImage: 'https://cdn.myanimelist.net/images/anime/10/69661.jpg',
          orderIndex: 3,
          note: 'Canon oficial de la Kishimoto: Vizionează înainte de ultimele episoade Shippuuden (ep 494+)!',
          isCanon: true,
        },
        {
          id: 'boruto-tv',
          mediaId: 'anilist-97938',
          title: 'Boruto: Naruto Next Generations',
          type: 'TV',
          episodesInfo: '293 Episoade',
          releaseYear: 2017,
          coverImage: 'https://cdn.myanimelist.net/images/anime/9/84933.jpg',
          orderIndex: 4,
          note: 'Seria TV a noii generații de ninja din Konoha.',
          isCanon: true,
        },
      ],
      RELEASE: [],
      CHRONOLOGICAL: [],
    },
  },
  'demon-slayer': {
    franchiseId: 'demon-slayer',
    franchiseName: 'Universul Demon Slayer (Kimetsu no Yaiba)',
    description: 'Povestea lui Tanjiro Kamado și a surorii sale Nezuko în lupta împotriva demonilor.',
    communityTip: '✨ Ghid Demon Slayer: Sezonul 1 ➔ Filmul Mugen Train (sau Mugen Train Arc TV) ➔ Entertainment District Arc ➔ Swordsmith Village Arc ➔ Hashira Training Arc.',
    paths: {
      RECOMMENDED: [
        {
          id: 'ds-s1',
          mediaId: 'anilist-101922',
          title: 'Demon Slayer: Kimetsu no Yaiba S1',
          type: 'TV',
          episodesInfo: '26 Episoade (2019)',
          releaseYear: 2019,
          orderIndex: 1,
          note: 'Începutul călătoriei lui Tanjiro și Selecția Finală.',
          isCanon: true,
        },
        {
          id: 'ds-mugen-movie',
          mediaId: 'anilist-112151',
          title: 'Demon Slayer: Mugen Train (Movie)',
          type: 'MOVIE',
          episodesInfo: '1 Film (117 min)',
          releaseYear: 2020,
          orderIndex: 2,
          note: 'Trenul Infinit alături de Rengoku Kyojuro.',
          isCanon: true,
        },
        {
          id: 'ds-s2',
          mediaId: 'anilist-129874',
          title: 'Entertainment District Arc',
          type: 'TV',
          episodesInfo: '11 Episoade (2021)',
          releaseYear: 2021,
          orderIndex: 3,
          note: 'Misiunea din Cartierul Roșu alături de Tengen Uzui.',
          isCanon: true,
        },
      ],
      RELEASE: [],
      CHRONOLOGICAL: [],
    },
  },
  'attack-on-titan': {
    franchiseId: 'attack-on-titan',
    canonicalRoot: 'shingekinokyojin',
    franchiseName: 'Universul Attack on Titan (Shingeki no Kyojin)',
    description: 'Lupta umanității pentru supraviețuire împotriva titanilor din spatele zidurilor.',
    communityTip: '✨ Ordine: Sezonul 1 ➔ Sezonul 2 ➔ Sezonul 3 (Partea 1 & 2) ➔ The Final Season (Toate Părțile).',
    paths: {
      RECOMMENDED: [
        {
          id: 'aot-s1',
          mediaId: 'anilist-16498',
          title: 'Attack on Titan S1',
          type: 'TV',
          episodesInfo: '25 Episoade (2013)',
          releaseYear: 2013,
          orderIndex: 1,
          note: 'Căderea Zidului Maria și înrolarea lui Eren în Regimentul Scout.',
          isCanon: true,
        },
        {
          id: 'aot-s2',
          mediaId: 'anilist-20958',
          title: 'Attack on Titan S2',
          type: 'TV',
          episodesInfo: '12 Episoade (2017)',
          releaseYear: 2017,
          orderIndex: 2,
          note: 'Aflarea adevărului despre Titanii din zid.',
          isCanon: true,
        },
      ],
      RELEASE: [],
      CHRONOLOGICAL: [],
    },
  },
};

export async function getWatchOrderGuide(env: Bindings, mediaId: string): Promise<any | null> {
  const item = await getMediaById(env, mediaId);
  const titleLower = (item?.title?.userPreferred || item?.title?.english || item?.title?.romaji || '').toLowerCase();

  // Naruto
  if (
    mediaId === 'anilist-20' ||
    mediaId === 'anilist-1735' ||
    titleLower.includes('naruto') ||
    titleLower.includes('boruto')
  ) {
    return FRANCHISE_GUIDES['naruto-series'];
  }

  // Demon Slayer
  if (
    mediaId === 'anilist-101922' ||
    titleLower.includes('demon slayer') ||
    titleLower.includes('kimetsu no yaiba')
  ) {
    return FRANCHISE_GUIDES['demon-slayer'];
  }

  // Attack on Titan
  if (
    mediaId === 'anilist-16498' ||
    mediaId === 'anilist-20958' ||
    titleLower.includes('attack on titan') ||
    titleLower.includes('shingeki no kyojin')
  ) {
    return FRANCHISE_GUIDES['attack-on-titan'];
  }

  if (item) {
    const rootTitle = sanitizeRoot(item.title?.userPreferred || '');
    const baseName = (item.title?.userPreferred || '').split(/[:\-]/)[0].trim();
    const rels = (item.relations || []).filter((r: any) => r.type !== 'MANGA');
    const pathItems = [
      {
        id: `dyn-${item.id}`,
        mediaId: item.id,
        title: item.title?.userPreferred,
        type: item.format || 'TV',
        episodesInfo: item.episodes ? `${item.episodes} Episoade` : 'Special',
        releaseYear: item.year,
        coverImage: item.coverImage?.large,
        orderIndex: 1,
        note: 'Punctul principal de intrare în serie.',
        isCanon: true,
      },
      ...rels.map((r: any, idx: number) => ({
        id: `dyn-${r.id}`,
        mediaId: r.id,
        title: r.title,
        type: r.format || 'TV',
        episodesInfo: r.episodes ? `${r.episodes} Episoade` : 'Conex',
        releaseYear: r.releaseYear,
        coverImage: r.coverImage,
        orderIndex: idx + 2,
        note: `Relație oficială: ${r.relationType}`,
        isCanon: r.relationType === 'SEQUEL' || r.relationType === 'PREQUEL',
      }))
    ];

    return {
      franchiseId: item.franchiseId || `dynamic-${rootTitle}`,
      franchiseName: `Universul ${baseName}`,
      description: `Ghidul cronologic și de lansare pentru seria ${baseName}.`,
      communityTip: `✨ Ghid ${baseName}: Ordine cronologică generată din producțiile oficiale ale francizei.`,
      paths: {
        RECOMMENDED: pathItems,
        CHRONOLOGICAL: pathItems,
        RELEASE: pathItems,
      }
    };
  }

  return null;
}
