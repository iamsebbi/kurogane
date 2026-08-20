'use client';

import React, { useState, useRef, useEffect, useCallback } from 'react';
import {
  X,
  Mail,
  Lock,
  User,
  Sparkles,
  ArrowRight,
  Eye,
  EyeOff,
  CheckCircle2,
  AlertCircle,
  KeyRound,
  Flame,
  Loader2,
} from 'lucide-react';
import { firebaseAuth, isFirebaseConfigured } from '@/lib/firebase';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (user: any, token: string) => void;
  initialMode?: AuthMode;
}

type AuthMode = 'SIGN_IN' | 'SIGN_UP' | 'FORGOT_PASSWORD' | 'OTP_LOGIN';

// Email regex per RFC 5322 simplified
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const USERNAME_REGEX = /^[a-zA-Z0-9_.\-\u00C0-\u024F]{2,24}$/;
const PASSWORD_MIN = 6;

export function AuthModal({ isOpen, onClose, onSuccess, initialMode = 'SIGN_IN' }: AuthModalProps) {
  const [mode, setMode] = useState<AuthMode>(initialMode);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [username, setUsername] = useState('');
  const [otpCode, setOtpCode] = useState('');
  const [otpStep, setOtpStep] = useState<'SEND' | 'VERIFY'>('SEND');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const modalRef = useRef<HTMLDivElement>(null);
  const firstInputRef = useRef<HTMLInputElement>(null);
  const errorRef = useRef<HTMLDivElement>(null);

  // Sync mode when modal opens
  useEffect(() => {
    if (isOpen) {
      setMode(initialMode);
      setError(null);
      setSuccessMsg(null);
    }
  }, [isOpen, initialMode]);

  // Focus first input on mode change
  useEffect(() => {
    if (isOpen) {
      requestAnimationFrame(() => {
        firstInputRef.current?.focus();
      });
    }
  }, [isOpen, mode, otpStep]);

  // Focus error when it appears (screen reader + scroll)
  useEffect(() => {
    if (error && errorRef.current) {
      errorRef.current.focus();
    }
  }, [error]);

  // Close on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  // Close on backdrop click
  const handleBackdropClick = useCallback(
    (e: React.MouseEvent) => {
      if (modalRef.current && !modalRef.current.contains(e.target as Node)) {
        onClose();
      }
    },
    [onClose]
  );

  if (!isOpen) return null;

  const resetForm = () => {
    setError(null);
    setSuccessMsg(null);
  };

  const validateEmail = (val: string): string | null => {
    const trimmed = val.trim();
    if (!trimmed) return 'Adresa de email este obligatorie.';
    if (!EMAIL_REGEX.test(trimmed)) return 'Adresa de email nu este validă.';
    return null;
  };

  const validatePassword = (val: string): string | null => {
    if (!val) return 'Parola este obligatorie.';
    if (val.length < PASSWORD_MIN) return `Parola trebuie să conțină cel puțin ${PASSWORD_MIN} caractere.`;
    return null;
  };

  const validateUsername = (val: string): string | null => {
    const trimmed = val.trim();
    if (!trimmed) return 'Numele de utilizator este obligatoriu.';
    if (trimmed.length < 2) return 'Numele de utilizator trebuie să aibă cel puțin 2 caractere.';
    if (trimmed.length > 24) return 'Numele de utilizator nu poate depăși 24 de caractere.';
    if (!USERNAME_REGEX.test(trimmed)) return 'Numele poate conține doar litere, cifre, underscore, punct și cratimă.';
    return null;
  };

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    resetForm();

    const cleanEmail = email.trim().toLowerCase();
    const emailErr = validateEmail(cleanEmail);
    if (emailErr) { setError(emailErr); return; }
    const passErr = validatePassword(password);
    if (passErr) { setError(passErr); return; }

    setLoading(true);

    try {
      const { user, token, error: fbError } = await firebaseAuth.signInWithPassword(cleanEmail, password);

      if (fbError || !user || !token) {
        throw fbError || new Error('Autentificarea a eșuat.');
      }

      localStorage.setItem('kurogane_token', token);
      localStorage.setItem('kurogane_user', JSON.stringify(user));
      window.dispatchEvent(new Event('kurogane_auth_changed'));
      onSuccess(user, token);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Datele de autentificare sunt incorecte.');
    } finally {
      setLoading(false);
    }
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    resetForm();

    const cleanEmail = email.trim().toLowerCase();
    const cleanUsername = username.trim();

    const userErr = validateUsername(cleanUsername);
    if (userErr) { setError(userErr); return; }
    const emailErr = validateEmail(cleanEmail);
    if (emailErr) { setError(emailErr); return; }
    const passErr = validatePassword(password);
    if (passErr) { setError(passErr); return; }
    if (password !== confirmPassword) {
      setError('Parolele introduse nu se potrivesc.');
      return;
    }

    setLoading(true);

    try {
      const { user, token, error: fbError } = await firebaseAuth.signUpWithPassword(cleanEmail, password, cleanUsername);

      if (fbError || !user || !token) {
        throw fbError || new Error('Eroare la crearea contului.');
      }

      localStorage.setItem('kurogane_token', token);
      localStorage.setItem('kurogane_user', JSON.stringify(user));
      window.dispatchEvent(new Event('kurogane_auth_changed'));
      onSuccess(user, token);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Eroare la crearea contului Firebase.');
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    resetForm();

    const cleanEmail = email.trim().toLowerCase();
    const emailErr = validateEmail(cleanEmail);
    if (emailErr) { setError(emailErr); return; }

    setLoading(true);

    try {
      const { success, error: fbError } = await firebaseAuth.sendPasswordResetEmail(cleanEmail);

      if (fbError || !success) {
        throw fbError || new Error('Eroare la trimiterea emailului de resetare.');
      }

      setSuccessMsg(`Un link de resetare a parolei a fost trimis la adresa ${cleanEmail}.`);
    } catch (err: any) {
      setError(err.message || 'Eroare la trimiterea email-ului de resetare.');
    } finally {
      setLoading(false);
    }
  };

  const handleSendResendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    resetForm();

    const cleanEmail = email.trim().toLowerCase();
    const emailErr = validateEmail(cleanEmail);
    if (emailErr) { setError(emailErr); return; }

    setLoading(true);

    try {
      const res = await fetch('http://localhost:4000/api/auth/send-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: cleanEmail }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Eroare la trimiterea codului OTP.');
      }

      setSuccessMsg(data.message || `Codul OTP a fost trimis pe ${cleanEmail}`);
      setOtpStep('VERIFY');
    } catch (err: any) {
      setError(err.message || 'Eroare la trimiterea codului de securitate.');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyResendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    resetForm();

    const cleanEmail = email.trim().toLowerCase();
    const trimmedCode = otpCode.trim();

    if (!cleanEmail) {
      setError('Adresa de email este obligatorie.');
      return;
    }
    if (!trimmedCode || trimmedCode.length !== 6 || !/^\d{6}$/.test(trimmedCode)) {
      setError('Introdu un cod valid format din exact 6 cifre.');
      return;
    }

    setLoading(true);

    try {
      const res = await fetch('http://localhost:4000/api/auth/verify-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: cleanEmail, code: trimmedCode, username }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Codul de verificare este incorect.');
      }

      localStorage.setItem('kurogane_token', data.token);
      localStorage.setItem('kurogane_user', JSON.stringify(data.user));
      window.dispatchEvent(new Event('kurogane_auth_changed'));
      onSuccess(data.user, data.token);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Eroare la verificarea codului OTP.');
    } finally {
      setLoading(false);
    }
  };

  const handleOAuthLogin = async (provider: 'google' | 'discord' | 'github' | 'apple') => {
    try {
      resetForm();
      setLoading(true);

      let result: { user: any; token: string | null; error: Error | null };

      if (provider === 'google') {
        result = await firebaseAuth.signInWithGoogle();
      } else if (provider === 'github') {
        result = await firebaseAuth.signInWithGitHub();
      } else {
        // Discord & Apple require custom OIDC configuration in Firebase Console
        setError(`Conectarea cu ${provider.charAt(0).toUpperCase() + provider.slice(1)} va fi disponibilă în curând.`);
        setLoading(false);
        return;
      }

      // User cancelled the popup (closed the window)
      if (!result.error && !result.user) {
        setLoading(false);
        return;
      }

      if (result.error || !result.user || !result.token) {
        throw result.error || new Error(`Eroare la conectarea cu ${provider}.`);
      }

      localStorage.setItem('kurogane_token', result.token);
      localStorage.setItem('kurogane_user', JSON.stringify(result.user));
      window.dispatchEvent(new Event('kurogane_auth_changed'));
      onSuccess(result.user, result.token);
      onClose();
    } catch (err: any) {
      setError(err.message || `Eroare la conectarea cu ${provider}`);
    } finally {
      setLoading(false);
    }
  };

  /** Spinner shown inside submit buttons while loading */
  const ButtonSpinner = () => <Loader2 className="w-4 h-4 animate-spin" />;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in duration-200"
      role="dialog"
      aria-modal="true"
      aria-labelledby="auth-modal-title"
      onClick={handleBackdropClick}
    >
      <div
        ref={modalRef}
        className="bg-bgSurface border border-borderSubtle rounded-3xl w-full max-w-md p-6 sm:p-8 shadow-2xl relative overflow-hidden max-h-[90vh] overflow-y-auto overscroll-contain text-textPrimary"
      >
        {/* Ambient Glow */}
        <div className="absolute -top-20 -right-20 w-64 h-64 bg-accentPrimary/10 rounded-full blur-3xl pointer-events-none" />

        <button
          onClick={onClose}
          aria-label="Închide fereastra de autentificare"
          className="absolute top-4 right-4 p-2 rounded-xl text-textSecondary hover:text-textPrimary hover:bg-bgSurfaceHover transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Top Header */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-scoreGold/10 border border-scoreGold/20 text-scoreGold text-xs font-semibold mb-3">
            <Flame className="w-3.5 h-3.5 fill-scoreGold/20" aria-hidden="true" /> Securizat de Google Firebase Auth
          </div>
          <h2 id="auth-modal-title" className="text-2xl font-bold text-textPrimary font-heading">
            {mode === 'SIGN_IN' && 'Autentificare Cont'}
            {mode === 'SIGN_UP' && 'Creează un Cont Nou'}
            {mode === 'FORGOT_PASSWORD' && 'Resetare Parolă'}
            {mode === 'OTP_LOGIN' && 'Conectare cu Cod OTP'}
          </h2>
          <p className="text-xs text-textSecondary mt-1">
            {mode === 'SIGN_IN' && 'Introdu emailul și parola pentru a intra în profilul tău.'}
            {mode === 'SIGN_UP' && 'Alătură-te comunității Kurogane și colecționează serii anime/manga.'}
            {mode === 'FORGOT_PASSWORD' && 'Introdu emailul asociat contului tău pentru resetare.'}
            {mode === 'OTP_LOGIN' && 'Primește un cod securizat din 6 cifre pe email.'}
          </p>
        </div>

        {/* Tabs switcher */}
        {mode !== 'FORGOT_PASSWORD' && (
          <div role="tablist" aria-label="Mod de autentificare" className="grid grid-cols-3 p-1 bg-bgPrimary border border-borderSubtle rounded-2xl mb-5 text-[11px] font-semibold">
            {(['SIGN_IN', 'SIGN_UP', 'OTP_LOGIN'] as const).map((tab) => (
              <button
                key={tab}
                role="tab"
                aria-selected={mode === tab}
                onClick={() => { setMode(tab); resetForm(); }}
                className={`py-2 rounded-xl transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary ${
                  mode === tab
                    ? 'bg-accentPrimary text-white shadow-md'
                    : 'text-textSecondary hover:text-textPrimary'
                }`}
              >
                {tab === 'SIGN_IN' && 'Conectare'}
                {tab === 'SIGN_UP' && 'Înregistrare'}
                {tab === 'OTP_LOGIN' && 'Cod OTP'}
              </button>
            ))}
          </div>
        )}

        {/* Feedback alerts */}
        {error && (
          <div ref={errorRef} tabIndex={-1} role="alert" aria-live="polite" className="mb-4 p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-xs flex items-center gap-2 focus:outline-none">
            <AlertCircle className="w-4 h-4 shrink-0" aria-hidden="true" />
            <span>{error}</span>
          </div>
        )}

        {successMsg && (
          <div role="status" aria-live="polite" className="mb-4 p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 shrink-0" aria-hidden="true" />
            <span>{successMsg}</span>
          </div>
        )}

        {/* SIGN IN FORM */}
        {mode === 'SIGN_IN' && (
          <form onSubmit={handleSignIn} className="space-y-3" noValidate>
            <div>
              <label htmlFor="signin-email" className="block text-xs text-textSecondary mb-1 font-medium">Adresa de Email</label>
              <div className="relative">
                <Mail className="w-4 h-4 text-textSecondary absolute left-3.5 top-3" aria-hidden="true" />
                <input
                  ref={firstInputRef}
                  id="signin-email"
                  type="email"
                  name="email"
                  autoComplete="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="nume@domeniu.com"
                  spellCheck={false}
                  className="w-full bg-bgPrimary border border-borderSubtle rounded-xl pl-10 pr-4 py-2.5 text-sm text-textPrimary placeholder-textMuted focus:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary transition-all"
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between items-center mb-1">
                <label htmlFor="signin-password" className="block text-xs text-textSecondary font-medium">Parolă</label>
                <button
                  type="button"
                  onClick={() => setMode('FORGOT_PASSWORD')}
                  className="text-[11px] text-accentPrimary hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary rounded"
                >
                  Ai uitat parola?
                </button>
              </div>
              <div className="relative">
                <Lock className="w-4 h-4 text-textSecondary absolute left-3.5 top-3" aria-hidden="true" />
                <input
                  id="signin-password"
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-bgPrimary border border-borderSubtle rounded-xl pl-10 pr-10 py-2.5 text-sm text-textPrimary placeholder-textMuted focus:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Ascunde parola' : 'Arată parola'}
                  className="absolute right-3.5 top-3 text-textSecondary hover:text-textPrimary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary rounded"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 rounded-xl bg-accentPrimary hover:opacity-90 text-white font-bold text-xs shadow-lg transition-all flex items-center justify-center gap-2 disabled:opacity-50 mt-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary"
            >
              {loading ? <ButtonSpinner /> : null}
              <span>Conectare în Cont</span>
              {!loading && <ArrowRight className="w-4 h-4" />}
            </button>
          </form>
        )}

        {/* SIGN UP FORM */}
        {mode === 'SIGN_UP' && (
          <form onSubmit={handleSignUp} className="space-y-3" noValidate>
            <div>
              <label htmlFor="signup-username" className="block text-xs text-textSecondary mb-1 font-medium">Nume Utilizator</label>
              <div className="relative">
                <User className="w-4 h-4 text-textSecondary absolute left-3.5 top-3" aria-hidden="true" />
                <input
                  ref={firstInputRef}
                  id="signup-username"
                  type="text"
                  name="username"
                  autoComplete="username"
                  required
                  maxLength={24}
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="Ex: OtakuMaster…"
                  spellCheck={false}
                  className="w-full bg-bgPrimary border border-borderSubtle rounded-xl pl-10 pr-4 py-2.5 text-sm text-textPrimary placeholder-textMuted focus:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary transition-all"
                />
              </div>
            </div>

            <div>
              <label htmlFor="signup-email" className="block text-xs text-textSecondary mb-1 font-medium">Adresa de Email</label>
              <div className="relative">
                <Mail className="w-4 h-4 text-textSecondary absolute left-3.5 top-3" aria-hidden="true" />
                <input
                  id="signup-email"
                  type="email"
                  name="email"
                  autoComplete="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="nume@domeniu.com"
                  spellCheck={false}
                  className="w-full bg-bgPrimary border border-borderSubtle rounded-xl pl-10 pr-4 py-2.5 text-sm text-textPrimary placeholder-textMuted focus:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary transition-all"
                />
              </div>
            </div>

            <div>
              <label htmlFor="signup-password" className="block text-xs text-textSecondary mb-1 font-medium">Parolă (min. 6 caractere)</label>
              <div className="relative">
                <Lock className="w-4 h-4 text-textSecondary absolute left-3.5 top-3" aria-hidden="true" />
                <input
                  id="signup-password"
                  type={showPassword ? 'text' : 'password'}
                  name="new-password"
                  autoComplete="new-password"
                  required
                  minLength={6}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-bgPrimary border border-borderSubtle rounded-xl pl-10 pr-10 py-2.5 text-sm text-textPrimary placeholder-textMuted focus:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Ascunde parola' : 'Arată parola'}
                  className="absolute right-3.5 top-3 text-textSecondary hover:text-textPrimary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary rounded"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <div>
              <label htmlFor="signup-confirm-password" className="block text-xs text-textSecondary mb-1 font-medium">Confirmă Parola</label>
              <div className="relative">
                <Lock className="w-4 h-4 text-textSecondary absolute left-3.5 top-3" aria-hidden="true" />
                <input
                  id="signup-confirm-password"
                  type={showPassword ? 'text' : 'password'}
                  name="confirm-password"
                  autoComplete="new-password"
                  required
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-bgPrimary border border-borderSubtle rounded-xl pl-10 pr-4 py-2.5 text-sm text-textPrimary placeholder-textMuted focus:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary transition-all"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 rounded-xl bg-accentPrimary hover:opacity-90 text-white font-bold text-xs shadow-lg transition-all flex items-center justify-center gap-2 disabled:opacity-50 mt-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary"
            >
              {loading ? <ButtonSpinner /> : null}
              <span>Creează Cont Kurogane</span>
              {!loading && <Sparkles className="w-4 h-4" />}
            </button>
          </form>
        )}

        {/* FORGOT PASSWORD FORM */}
        {mode === 'FORGOT_PASSWORD' && (
          <form onSubmit={handleForgotPassword} className="space-y-4" noValidate>
            <div>
              <label htmlFor="reset-email" className="block text-xs text-slate-400 mb-1 font-medium">Email-ul asociat contului tău</label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-500 absolute left-3.5 top-3" aria-hidden="true" />
                <input
                  ref={firstInputRef}
                  id="reset-email"
                  type="email"
                  name="email"
                  autoComplete="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="nume@domeniu.com"
                  spellCheck={false}
                  className="w-full bg-slate-900/90 border border-slate-800 rounded-xl pl-10 pr-4 py-2.5 text-sm text-slate-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-amber-500 transition-all"
                />
              </div>
            </div>

            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => {
                  setMode('SIGN_IN');
                  resetForm();
                }}
                className="w-1/3 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold text-xs transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-500"
              >
                Înapoi
              </button>
              <button
                type="submit"
                disabled={loading || !email.trim()}
                className="w-2/3 py-2.5 rounded-xl bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-bold text-xs shadow-lg shadow-amber-600/20 transition-all flex items-center justify-center gap-2 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-400"
              >
                {loading ? <ButtonSpinner /> : null}
                <span>Trimite Link Resetare</span>
                {!loading && <KeyRound className="w-4 h-4" />}
              </button>
            </div>
          </form>
        )}

        {/* RESEND OTP LOGIN FORM */}
        {mode === 'OTP_LOGIN' && (
          <div className="space-y-4">
            {otpStep === 'SEND' ? (
              <form onSubmit={handleSendResendOtp} className="space-y-3" noValidate>
                <div>
                  <label htmlFor="otp-email" className="block text-xs text-slate-400 mb-1 font-medium">Adresa de Email pentru Cod OTP</label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-slate-500 absolute left-3.5 top-3" aria-hidden="true" />
                    <input
                      ref={firstInputRef}
                      id="otp-email"
                      type="email"
                      name="email"
                      autoComplete="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="nume@domeniu.com"
                      spellCheck={false}
                      className="w-full bg-slate-900/90 border border-slate-800 rounded-xl pl-10 pr-4 py-2.5 text-sm text-slate-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-amber-500 transition-all"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading || !email.trim()}
                  className="w-full py-3 rounded-xl bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-bold text-xs shadow-lg shadow-amber-600/20 transition-all flex items-center justify-center gap-2 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-400"
                >
                  {loading ? <ButtonSpinner /> : null}
                  <span>Trimite Cod OTP pe Email</span>
                  {!loading && <ArrowRight className="w-4 h-4" />}
                </button>
              </form>
            ) : (
              <form onSubmit={handleVerifyResendOtp} className="space-y-4" noValidate>
                <div>
                  <label htmlFor="otp-code" className="block text-xs text-slate-400 mb-1 font-medium">Introdu Codul de 6 Cifre primit pe email</label>
                  <input
                    id="otp-code"
                    type="text"
                    name="one-time-code"
                    autoComplete="one-time-code"
                    inputMode="numeric"
                    pattern="\d{6}"
                    required
                    maxLength={6}
                    value={otpCode}
                    onChange={(e) => {
                      const val = e.target.value.replace(/\D/g, '');
                      setOtpCode(val);
                    }}
                    placeholder="000000"
                    spellCheck={false}
                    className="w-full bg-slate-900 border border-slate-800 rounded-xl px-4 py-3 text-center text-lg font-mono tracking-widest text-slate-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-amber-500 transition-all"
                  />
                </div>

                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => { setOtpStep('SEND'); setOtpCode(''); resetForm(); }}
                    className="w-1/3 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold text-xs transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-500"
                  >
                    Înapoi
                  </button>
                  <button
                    type="submit"
                    disabled={loading || otpCode.trim().length !== 6}
                    className="w-2/3 py-2.5 rounded-xl bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-bold text-xs shadow-lg shadow-amber-600/20 transition-all flex items-center justify-center gap-2 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-400"
                  >
                    {loading ? <ButtonSpinner /> : null}
                    <span>Verifică & Conectează</span>
                    {!loading && <CheckCircle2 className="w-4 h-4" />}
                  </button>
                </div>
              </form>
            )}
          </div>
        )}

        {/* Social OAuth Buttons */}
        {mode !== 'FORGOT_PASSWORD' && (
          <>
            <div className="relative my-4 text-center">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-borderSubtle" />
              </div>
              <span className="relative bg-bgSurface px-3 text-[11px] font-medium text-textSecondary uppercase tracking-wider">
                Sau Autentificare Socială
              </span>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                disabled={loading}
                onClick={() => handleOAuthLogin('google')}
                className="py-2.5 px-3 rounded-xl bg-bgPrimary hover:bg-bgSurfaceHover text-textPrimary font-semibold text-xs flex items-center justify-center gap-2 border border-borderSubtle shadow-sm transition-all active:scale-98 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary"
              >
                <svg className="w-4 h-4 shrink-0" viewBox="0 0 24 24" aria-hidden="true">
                  <path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17z" />
                  <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.29v3.15C3.26 21.3 7.37 24 12 24z" />
                  <path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.29c-.8 1.6-1.29 3.39-1.29 5.42s.49 3.82 1.29 5.42l3.99-3.15z" />
                  <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.37 0 3.26 2.7 1.29 6.58l3.99 3.15c.95-2.83 3.6-4.98 6.72-4.98z" />
                </svg>
                <span>Google</span>
              </button>

              <button
                type="button"
                disabled={loading}
                onClick={() => handleOAuthLogin('discord')}
                className="py-2.5 px-3 rounded-xl bg-[#5865F2] hover:bg-[#4752C4] text-white font-semibold text-xs flex items-center justify-center gap-2 shadow-md transition-all active:scale-98 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary"
              >
                <svg className="w-4 h-4 fill-current shrink-0" viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994.021-.041.001-.09-.041-.106a13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.061 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.893.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.028z" />
                </svg>
                <span>Discord</span>
              </button>

              <button
                type="button"
                disabled={loading}
                onClick={() => handleOAuthLogin('github')}
                className="py-2.5 px-3 rounded-xl bg-bgPrimary hover:bg-bgSurfaceHover text-textPrimary font-semibold text-xs flex items-center justify-center gap-2 border border-borderSubtle shadow-sm transition-all active:scale-98 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary"
              >
                <svg className="w-4 h-4 fill-current shrink-0" viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
                </svg>
                <span>GitHub</span>
              </button>

              <button
                type="button"
                disabled={loading}
                onClick={() => handleOAuthLogin('apple')}
                className="py-2.5 px-3 rounded-xl bg-bgPrimary hover:bg-bgSurfaceHover text-textPrimary font-semibold text-xs flex items-center justify-center gap-2 border border-borderSubtle shadow-sm transition-all active:scale-98 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary"
              >
                <svg className="w-4 h-4 fill-current shrink-0" viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.45c.66-.8 1.11-1.92.99-3.04-.96.04-2.12.64-2.8 1.44-.61.71-1.15 1.86-1.01 2.97 1.08.08 2.16-.57 2.82-1.37z" />
                </svg>
                <span>Apple</span>
              </button>
            </div>
          </>
        )}

        <div className="mt-6 text-center text-[10px] text-textSecondary border-t border-borderSubtle pt-4">
          Autentificarea este securizată prin Google Firebase Auth. Parolele sunt criptate și securizate.
        </div>
      </div>
    </div>
  );
}
