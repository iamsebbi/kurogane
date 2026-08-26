import { initializeApp, getApps } from 'firebase/app';
import {
  getAuth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail as fbSendPasswordResetEmail,
  signInWithPopup,
  GoogleAuthProvider,
  GithubAuthProvider,
  updateProfile,
  onAuthStateChanged,
  signOut as fbSignOut,
} from 'firebase/auth';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || '',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || '',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || '',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || '',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '',
};

export const isFirebaseConfigured = Boolean(
  firebaseConfig.apiKey && firebaseConfig.projectId
);

// Initialize Firebase (singleton)
const app =
  getApps().length === 0 && isFirebaseConfigured
    ? initializeApp(firebaseConfig)
    : getApps().length > 0
      ? getApps()[0]
      : null;

const auth = app ? getAuth(app) : (null as any);

export interface FirebaseAuthUser {
  id: string;
  email: string;
  username: string;
  avatarUrl?: string;
  bio?: string;
  pronouns?: string;
  bannerUrl?: string;
  favoriteGenres?: string[];
  createdAt?: string;
  idToken?: string;
}

class FirebaseAuthService {
  /**
   * Sign In with Email & Password
   */
  public async signInWithPassword(email: string, password: string): Promise<{ user: FirebaseAuthUser | null; token: string | null; error: Error | null }> {
    const cleanEmail = email.trim().toLowerCase();

    try {
      const credential = await signInWithEmailAndPassword(auth, cleanEmail, password);
      const idToken = await credential.user.getIdToken();

      const user: FirebaseAuthUser = {
        id: credential.user.uid,
        email: credential.user.email || cleanEmail,
        username: credential.user.displayName || cleanEmail.split('@')[0],
        avatarUrl: credential.user.photoURL || `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(cleanEmail)}`,
        idToken,
      };

      return { user, token: idToken, error: null };
    } catch (err: any) {
      return { user: null, token: null, error: new Error(this.formatErrorMessage(err.code || err.message || '')) };
    }
  }

  /**
   * Sign Up with Email & Password + Display Name
   */
  public async signUpWithPassword(email: string, password: string, username: string): Promise<{ user: FirebaseAuthUser | null; token: string | null; error: Error | null }> {
    const cleanEmail = email.trim().toLowerCase();
    const cleanUsername = username.trim() || cleanEmail.split('@')[0];

    try {
      const credential = await createUserWithEmailAndPassword(auth, cleanEmail, password);

      // Set display name
      await updateProfile(credential.user, { displayName: cleanUsername }).catch(() => {});

      const idToken = await credential.user.getIdToken();

      const user: FirebaseAuthUser = {
        id: credential.user.uid,
        email: credential.user.email || cleanEmail,
        username: cleanUsername,
        avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(cleanUsername)}`,
        idToken,
      };

      return { user, token: idToken, error: null };
    } catch (err: any) {
      return { user: null, token: null, error: new Error(this.formatErrorMessage(err.code || err.message || '')) };
    }
  }

  /**
   * Send Password Reset Email
   */
  public async sendPasswordResetEmail(email: string): Promise<{ success: boolean; error: Error | null }> {
    const cleanEmail = email.trim().toLowerCase();

    try {
      await fbSendPasswordResetEmail(auth, cleanEmail);
      return { success: true, error: null };
    } catch (err: any) {
      return { success: false, error: new Error(this.formatErrorMessage(err.code || err.message || '')) };
    }
  }

  /**
   * Sign In with Google Popup (real OAuth2 flow)
   */
  public async signInWithGoogle(): Promise<{ user: FirebaseAuthUser | null; token: string | null; error: Error | null }> {
    try {
      const provider = new GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');

      const result = await signInWithPopup(auth, provider);
      const idToken = await result.user.getIdToken();

      const user: FirebaseAuthUser = {
        id: result.user.uid,
        email: result.user.email || '',
        username: result.user.displayName || result.user.email?.split('@')[0] || 'User',
        avatarUrl: result.user.photoURL || `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(result.user.uid)}`,
        idToken,
      };

      return { user, token: idToken, error: null };
    } catch (err: any) {
      if (err.code === 'auth/popup-closed-by-user' || err.code === 'auth/cancelled-popup-request') {
        return { user: null, token: null, error: null }; // User cancelled, no error
      }
      return { user: null, token: null, error: new Error(this.formatErrorMessage(err.code || err.message || '')) };
    }
  }

  /**
   * Sign In with GitHub Popup (real OAuth2 flow)
   */
  public async signInWithGitHub(): Promise<{ user: FirebaseAuthUser | null; token: string | null; error: Error | null }> {
    try {
      const provider = new GithubAuthProvider();
      provider.addScope('user:email');

      const result = await signInWithPopup(auth, provider);
      const idToken = await result.user.getIdToken();

      const user: FirebaseAuthUser = {
        id: result.user.uid,
        email: result.user.email || '',
        username: result.user.displayName || result.user.email?.split('@')[0] || 'User',
        avatarUrl: result.user.photoURL || `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(result.user.uid)}`,
        idToken,
      };

      return { user, token: idToken, error: null };
    } catch (err: any) {
      if (err.code === 'auth/popup-closed-by-user' || err.code === 'auth/cancelled-popup-request') {
        return { user: null, token: null, error: null };
      }
      return { user: null, token: null, error: new Error(this.formatErrorMessage(err.code || err.message || '')) };
    }
  }

  /**
   * Listen to Firebase native auth state changes across all tabs
   */
  public onAuthStateChange(callback: (user: FirebaseAuthUser | null, token: string | null) => void) {
    if (!auth) {
      callback(null, null);
      return () => {};
    }
    return onAuthStateChanged(auth, async (fbUser) => {
      if (fbUser) {
        const idToken = await fbUser.getIdToken();
        const user: FirebaseAuthUser = {
          id: fbUser.uid,
          email: fbUser.email || '',
          username: fbUser.displayName || fbUser.email?.split('@')[0] || 'User',
          avatarUrl: fbUser.photoURL || `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(fbUser.uid)}`,
          idToken,
        };
        callback(user, idToken);
      } else {
        callback(null, null);
      }
    });
  }

  /**
   * Sign Out from Firebase Auth
   */
  public async signOut(): Promise<void> {
    if (!auth) return;
    try {
      await fbSignOut(auth);
    } catch (err) {
      console.error('Error signing out from Firebase:', err);
    }
  }

  /**
   * Format Firebase error codes to friendly Romanian user messages
   */
  private formatErrorMessage(code: string): string {
    if (code.includes('email-already-in-use')) return 'Această adresă de email este deja înregistrată. Conectează-te în cont!';
    if (code.includes('invalid-credential') || code.includes('wrong-password') || code.includes('invalid-login-credentials')) return 'Emailul sau parola sunt incorecte.';
    if (code.includes('user-not-found')) return 'Nu există niciun cont înregistrat cu acest email.';
    if (code.includes('weak-password')) return 'Parola este prea slabă. Folosește cel puțin 6 caractere.';
    if (code.includes('user-disabled')) return 'Acest cont a fost dezactivat de administrator.';
    if (code.includes('too-many-requests')) return 'Prea multe încercări eșuate. Încearcă din nou mai târziu.';
    if (code.includes('network-request-failed')) return 'Eroare de rețea. Verifică conexiunea la internet.';
    if (code.includes('popup-blocked')) return 'Fereastra popup a fost blocată de browser. Permite popup-urile pentru acest site.';
    if (code.includes('account-exists-with-different-credential')) return 'Un cont cu acest email există deja folosind altă metodă de conectare.';
    if (code.includes('unauthorized-domain')) return 'Domeniul curent nu este autorizat în Firebase Console. Adaugă domeniul exact în Firebase -> Authentication -> Settings -> Authorized domains.';
    if (code.includes('invalid-email')) return 'Adresa de email nu este validă.';
    return code || 'A apărut o eroare neașteptată.';
  }
}

export const firebaseAuth = new FirebaseAuthService();
