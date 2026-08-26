import './env';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  process.env.SUPABASE_ANON_KEY ||
  '';

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseKey);

export const supabase: SupabaseClient | null = isSupabaseConfigured
  ? createClient(supabaseUrl, supabaseKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    })
  : null;

if (isSupabaseConfigured && supabase) {
  console.log('⚡ [Supabase] Connected to Supabase PostgreSQL cluster.');

  // Keep-Alive Heartbeat to prevent Supabase Free Tier auto-pause
  const pingDatabase = async () => {
    try {
      await supabase.from('users').select('id').limit(1);
    } catch (e) {}
  };

  // Run ping on startup and every 12 hours
  pingDatabase();
  const heartbeatTimer = setInterval(pingDatabase, 12 * 60 * 60 * 1000);
  heartbeatTimer.unref();
} else {
  console.log('📂 [Storage Mode] Supabase credentials not set. Running in local JSON/In-Memory fallback mode.');
}
