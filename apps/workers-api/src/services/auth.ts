import { jwtVerify, createRemoteJWKSet, SignJWT } from 'jose';
import { Bindings, UserProfile } from '../types';

let cachedFirebaseJWKS: ReturnType<typeof createRemoteJWKSet> | null = null;

function getFirebaseJWKS() {
  if (!cachedFirebaseJWKS) {
    cachedFirebaseJWKS = createRemoteJWKSet(
      new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com')
    );
  }
  return cachedFirebaseJWKS;
}

export async function verifyToken(
  env: Bindings,
  authHeader?: string | null
): Promise<UserProfile | null> {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.substring(7).trim();
  if (!token) return null;

  // 1. Kurogane Local JWT check
  try {
    const secretKey = new TextEncoder().encode(env.JWT_SECRET || 'kurogane_secure_development_jwt_secret_key_2026_min32chars');
    const { payload } = await jwtVerify(token, secretKey);
    if (payload && payload.sub) {
      const userId = payload.sub as string;
      const user = await getUserById(env.DB, userId);
      if (user) return user;

      // Restored user profile
      const restored: UserProfile = {
        id: userId,
        email: payload.email as string || undefined,
        username: (payload.username as string) || (payload.email ? (payload.email as string).split('@')[0] : 'User'),
        avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(payload.sub)}`,
        bio: 'Entuziast Anime & Manga pe Kurogane.',
        pronouns: 'he/him',
        bannerUrl: 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
        createdAt: new Date().toISOString(),
      };
      await upsertUser(env.DB, restored);
      return restored;
    }
  } catch (err) {
    // Not a local HMAC JWT, continue to Firebase check
  }

  // 2. Firebase ID Token check (Google JWKS)
  try {
    const projectId = env.FIREBASE_PROJECT_ID || 'kurogane-c3c14';
    const JWKS = getFirebaseJWKS();
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
    });

    if (payload && payload.sub) {
      const uid = payload.sub;
      const email = (payload.email as string || '').toLowerCase().trim();
      const name = (payload.name as string) || (email ? email.split('@')[0] : 'Otaku Explorer');

      // Check D1
      let user = await getUserById(env.DB, uid);
      if (!user && email) {
        user = await getUserByEmail(env.DB, email);
      }

      if (user) {
        return user;
      }

      // Auto-provision user in D1
      const newProfile: UserProfile = {
        id: uid,
        email: email || undefined,
        username: name,
        avatarUrl: (payload.picture as string) || `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(name)}`,
        bio: 'Entuziast Anime & Manga pe Kurogane.',
        pronouns: 'he/him',
        bannerUrl: 'linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)',
        createdAt: new Date().toISOString(),
      };

      await upsertUser(env.DB, newProfile);
      return newProfile;
    }
  } catch (err) {
    // Neither valid local JWT nor valid Firebase token
  }

  return null;
}

export async function getUserById(db: D1Database, id: string): Promise<UserProfile | null> {
  const row = await db.prepare('SELECT * FROM users WHERE id = ?').bind(id).first<any>();
  if (!row) return null;
  return mapUserRow(row);
}

export async function getUserByEmail(db: D1Database, email: string): Promise<UserProfile | null> {
  const row = await db.prepare('SELECT * FROM users WHERE LOWER(email) = LOWER(?)').bind(email.trim()).first<any>();
  if (!row) return null;
  return mapUserRow(row);
}

export async function getUserByUsername(db: D1Database, username: string): Promise<UserProfile | null> {
  const row = await db.prepare('SELECT * FROM users WHERE LOWER(username) = LOWER(?)').bind(username.trim()).first<any>();
  if (!row) return null;
  return mapUserRow(row);
}

export async function upsertUser(db: D1Database, user: UserProfile): Promise<void> {
  const favGenres = JSON.stringify(user.favoriteGenres || []);
  await db.prepare(`
    INSERT INTO users (id, email, username, avatar_url, bio, pronouns, banner_url, favorite_genres, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
    ON CONFLICT(id) DO UPDATE SET
      email = excluded.email,
      username = excluded.username,
      avatar_url = excluded.avatar_url,
      bio = excluded.bio,
      pronouns = excluded.pronouns,
      banner_url = excluded.banner_url,
      favorite_genres = excluded.favorite_genres,
      updated_at = datetime('now')
  `).bind(
    user.id,
    user.email || null,
    user.username,
    user.avatarUrl || null,
    user.bio || '',
    user.pronouns || 'he/him',
    user.bannerUrl || '',
    favGenres
  ).run();
}

function mapUserRow(row: any): UserProfile {
  let favGenres: string[] = [];
  try {
    favGenres = JSON.parse(row.favorite_genres || '[]');
  } catch (e) {
    favGenres = [];
  }

  return {
    id: row.id,
    email: row.email || undefined,
    username: row.username,
    avatarUrl: row.avatar_url || undefined,
    bio: row.bio || '',
    pronouns: row.pronouns || 'he/him',
    bannerUrl: row.banner_url || undefined,
    favoriteGenres: favGenres,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export async function generateToken(env: Bindings, user: UserProfile): Promise<string> {
  const secret = new TextEncoder().encode(env.JWT_SECRET || 'kurogane_secure_development_jwt_secret_key_2026_min32chars');
  return await new SignJWT({
    sub: user.id,
    email: user.email,
    username: user.username,
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setExpirationTime('7d')
    .sign(secret);
}
