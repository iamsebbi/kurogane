const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://demo-kurogane.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.demo-anon-key';

export const isSupabaseConfigured = Boolean(
  process.env.NEXT_PUBLIC_SUPABASE_URL && !process.env.NEXT_PUBLIC_SUPABASE_URL.includes('demo-kurogane')
);

export interface SignUpOptions {
  email: string;
  password?: string;
  options?: {
    data?: Record<string, any>;
    emailRedirectTo?: string;
  };
}

export interface SignInPasswordOptions {
  email: string;
  password?: string;
}

export interface OAuthOptions {
  provider: 'google' | 'discord' | 'github';
  options?: {
    redirectTo?: string;
  };
}

class SupabaseAuthClient {
  public auth = {
    signUp: async ({ email, password, options }: SignUpOptions) => {
      if (isSupabaseConfigured) {
        try {
          const res = await fetch(`${supabaseUrl}/auth/v1/signup`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              apikey: supabaseAnonKey,
            },
            body: JSON.stringify({
              email,
              password,
              data: options?.data,
            }),
          });
          const data = await res.json();
          if (!res.ok) {
            return { data: null, error: new Error(data.msg || data.error_description || 'Eroare la înregistrare.') };
          }
          return { data: { user: data.user || data, session: data.session || null }, error: null };
        } catch (err: any) {
          return { data: null, error: err };
        }
      }
      return { data: { user: { id: `user-${Date.now()}`, email }, session: null }, error: null };
    },

    signInWithPassword: async ({ email, password }: SignInPasswordOptions) => {
      if (isSupabaseConfigured) {
        try {
          const res = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              apikey: supabaseAnonKey,
            },
            body: JSON.stringify({ email, password }),
          });
          const data = await res.json();
          if (!res.ok) {
            return { data: null, error: new Error(data.error_description || data.msg || 'Date de conectare invalide.') };
          }
          return {
            data: {
              user: data.user,
              session: { access_token: data.access_token, refresh_token: data.refresh_token },
            },
            error: null,
          };
        } catch (err: any) {
          return { data: null, error: err };
        }
      }
      return { data: { user: null, session: null }, error: null };
    },

    resetPasswordForEmail: async (email: string, options?: { redirectTo?: string }) => {
      if (isSupabaseConfigured) {
        try {
          const res = await fetch(`${supabaseUrl}/auth/v1/recover`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              apikey: supabaseAnonKey,
            },
            body: JSON.stringify({ email }),
          });
          const data = await res.json();
          if (!res.ok) {
            return { data: null, error: new Error(data.msg || data.error_description || 'Eroare la trimiterea email-ului.') };
          }
          return { data, error: null };
        } catch (err: any) {
          return { data: null, error: err };
        }
      }
      return { data: { success: true }, error: null };
    },

    signInWithOAuth: async ({ provider, options }: OAuthOptions) => {
      if (typeof window !== 'undefined' && isSupabaseConfigured) {
        const redirect = options?.redirectTo || window.location.origin;
        const authUrl = `${supabaseUrl}/auth/v1/authorize?provider=${provider}&redirect_to=${encodeURIComponent(redirect)}`;
        window.location.href = authUrl;
        return { data: { provider, url: authUrl }, error: null, redirected: true };
      }
      return { data: { provider }, error: null, redirected: false };
    },

    signInWithOtp: async ({ email }: { email: string }) => {
      return { data: { email }, error: null };
    },

    getSession: async () => {
      return { data: { session: null }, error: null };
    },

    signOut: async () => {
      if (typeof window !== 'undefined') {
        localStorage.removeItem('kurogane_token');
        localStorage.removeItem('kurogane_user');
      }
      return { error: null };
    },
  };
}

export const supabase = new SupabaseAuthClient();
