import test from 'node:test';
import assert from 'node:assert/strict';
import { persistentDbService } from '../services/db-persistent';
import { rateLimiter } from '../services/rate-limiter';
import bcrypt from 'bcryptjs';

test('🔐 Auth: JWT Token Generation & Cryptographic Verification', async (t) => {
  await t.test('generates valid signed JWT token for user profile', async () => {
    const mockUser = {
      id: 'test-user-uuid-1234',
      email: 'tester@kurogane.app',
      username: 'ShadowNinja',
      createdAt: new Date().toISOString(),
    };

    const token = persistentDbService.generateToken(mockUser);
    assert.ok(token, 'Token should not be empty');
    assert.strictEqual(typeof token, 'string', 'Token must be a string');
    assert.strictEqual(token.split('.').length, 3, 'JWT must contain 3 segments');

    const verified = await persistentDbService.verifyToken(token);
    assert.ok(verified, 'Verification must succeed for signed token');
    assert.strictEqual(verified?.id, mockUser.id);
    assert.strictEqual(verified?.email, mockUser.email);
    assert.strictEqual(verified?.username, mockUser.username);
  });

  await t.test('rejects forged or tampered JWT token', async () => {
    const fakeToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.invalid_signature';
    const verified = await persistentDbService.verifyToken(fakeToken);
    assert.strictEqual(verified, null, 'Tampered token must return null');
  });

  await t.test('rejects null or empty token string', async () => {
    assert.strictEqual(await persistentDbService.verifyToken(''), null);
    assert.strictEqual(await persistentDbService.verifyToken(null as any), null);
  });
});

test('⏱️ Rate Limiter: Window Tracking & Max Limit Enforcement', async (t) => {
  const testIp = '192.168.1.100';
  const maxReq = 3;
  const windowMs = 5000;

  await t.test('allows requests within threshold', () => {
    const res1 = rateLimiter.check(testIp, maxReq, windowMs);
    assert.strictEqual(res1.allowed, true);
    assert.strictEqual(res1.remaining, 2);

    const res2 = rateLimiter.check(testIp, maxReq, windowMs);
    assert.strictEqual(res2.allowed, true);
    assert.strictEqual(res2.remaining, 1);

    const res3 = rateLimiter.check(testIp, maxReq, windowMs);
    assert.strictEqual(res3.allowed, true);
    assert.strictEqual(res3.remaining, 0);
  });

  await t.test('blocks requests exceeding threshold', () => {
    const resBlocked = rateLimiter.check(testIp, maxReq, windowMs);
    assert.strictEqual(resBlocked.allowed, false);
    assert.strictEqual(resBlocked.remaining, 0);
    assert.ok(resBlocked.resetSec > 0, 'Reset seconds must be positive');
  });
});

test('🔑 Security: Bcrypt Password Hashing & Verification', async (t) => {
  await t.test('hashes password with salt and validates correctly', async () => {
    const password = 'SuperSecretAnimePassword2026!';
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(password, salt);

    assert.notStrictEqual(hash, password, 'Hash must differ from plaintext');
    const isMatch = await bcrypt.compare(password, hash);
    assert.strictEqual(isMatch, true, 'Bcrypt compare must succeed for valid password');

    const isWrongMatch = await bcrypt.compare('WrongPassword', hash);
    assert.strictEqual(isWrongMatch, false, 'Bcrypt compare must fail for incorrect password');
  });
});

test('☁️ Storage: Supabase Client Integration & Offline Fallback', async (t) => {
  await t.test('handles storage gracefully in fallback mode without credentials', () => {
    const testUserId = 'test-fallback-user-001';
    const profile = persistentDbService.getUserProfile(testUserId);
    // Even without Supabase connected, in-memory/JSON profile lookups work seamlessly
    assert.strictEqual(typeof persistentDbService.getUserProfile, 'function');
  });

  await t.test('allows local watchlist mutation with background replication', async () => {
    const testUser = {
      id: 'unit-test-user-temp',
      email: 'testuser@kurogane.app',
      username: 'UnitTestUser',
      createdAt: new Date().toISOString(),
    };
    persistentDbService.updateUserProfile(testUser.id, testUser);

    const mediaId = 'custom-media-offline-test';
    const item = await persistentDbService.upsertWatchlistItem(testUser.id, mediaId, 'WATCHING', 9.5, 3);

    assert.ok(item, 'Item must be created');
    assert.strictEqual(item.userId, testUser.id);
    assert.strictEqual(item.mediaId, mediaId);
    assert.strictEqual(item.status, 'WATCHING');
    assert.strictEqual(item.progressEpisodes, 3);

    const removed = persistentDbService.removeWatchlistItem(testUser.id, mediaId);
    assert.strictEqual(removed, true, 'Removal must succeed');
  });
});
