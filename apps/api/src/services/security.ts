import crypto from 'crypto';

// Fixed dummy salt and hash for timing attack mitigation
const DUMMY_SALT = crypto.randomBytes(16);
const DUMMY_HASH = crypto.pbkdf2Sync('dummy_password_for_timing_mitigation', DUMMY_SALT, 12000, 32, 'sha256');

// List of most common compromised / weak passwords
const COMMON_WEAK_PASSWORDS = new Set([
  '12345678',
  '123456789',
  '1234567890',
  'password',
  'password1',
  'password123',
  'qwerty123',
  'iloveyou',
  'admin123',
  'welcome1',
  'kurogane',
  'kurogane123',
  'anime123',
  'otaku123',
]);

/**
 * Normalizes email or username identifiers for consistent matching and storage.
 * Eliminates case sensitivity anomalies and leading/trailing whitespace.
 */
export function normalizeIdentifier(val: string): string {
  if (!val || typeof val !== 'string') return '';
  return val.trim().toLowerCase();
}

/**
 * Executes a constant-time cryptographic computation that mirrors real password hashing.
 * Invoked when an account or identifier does not exist to prevent timing attacks / user enumeration.
 */
export async function performConstantTimeDummyHash(): Promise<void> {
  return new Promise((resolve) => {
    // Perform standard PBKDF2 iterations matching real password verification cost
    crypto.pbkdf2('dummy_input_for_constant_timing', DUMMY_SALT, 12000, 32, 'sha256', (err, derivedKey) => {
      try {
        crypto.timingSafeEqual(derivedKey, DUMMY_HASH);
      } catch {}
      resolve();
    });
  });
}

/**
 * Constant-time string comparison to prevent timing side-channel attacks.
 */
export function constantTimeCompare(a: string, b: string): boolean {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  if (bufA.length !== bufB.length) {
    // Perform dummy comparison of equal lengths to equalize timing
    crypto.timingSafeEqual(bufA, bufA);
    return false;
  }
  return crypto.timingSafeEqual(bufA, bufB);
}

/**
 * Checks if a password is in the common weak password blacklist.
 */
export function isCommonWeakPassword(password: string): boolean {
  if (!password) return true;
  return COMMON_WEAK_PASSWORDS.has(password.toLowerCase());
}
