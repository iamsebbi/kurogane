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
  Clock,
  RotateCcw,
} from 'lucide-react';
import { firebaseAuth } from '@/lib/firebase';
import { API_BASE_URL } from '../lib/api';

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

export function AuthModal({
  isOpen,
  onClose,
  onSuccess,
  initialMode = 'SIGN_IN',
}: AuthModalProps) {
  const [mode, setMode] = useState<AuthMode>(initialMode);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [username, setUsername] = useState('');
  const [otpCode, setOtpCode] = useState('');
  const [otpDigits, setOtpDigits] = useState<string[]>(['', '', '', '', '', '']);
  const [otpStep, setOtpStep] = useState<'SEND' | 'VERIFY'>('SEND');
  const [otpCooldown, setOtpCooldown] = useState<number>(0);
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const modalRef = useRef<HTMLDivElement>(null);
  const firstInputRef = useRef<HTMLInputElement>(null);
  const otpInputRefs = useRef<(HTMLInputElement | null)[]>([]);
  const errorRef = useRef<HTMLDivElement>(null);

  // Sync mode when modal opens
  useEffect(() => {
    if (isOpen) {
      setMode(initialMode);
      setError(null);
      setSuccessMsg(null);
    }
  }, [isOpen, initialMode]);

  // Desktop-only autofocus to avoid mobile virtual keyboard jump
  useEffect(() => {
    if (isOpen && typeof window !== 'undefined' && window.innerWidth >= 768) {
      requestAnimationFrame(() => {
        if (mode === 'OTP_LOGIN' && otpStep === 'VERIFY') {
          otpInputRefs.current[0]?.focus();
        } else {
          firstInputRef.current?.focus();
        }
      });
    }
  }, [isOpen, mode, otpStep]);

  // Focus first OTP input when transitioning to VERIFY step
  useEffect(() => {
    if (isOpen && mode === 'OTP_LOGIN' && otpStep === 'VERIFY') {
      requestAnimationFrame(() => {
        otpInputRefs.current[0]?.focus();
      });
    }
  }, [isOpen, mode, otpStep]);

  // Cooldown countdown timer for OTP requests
  useEffect(() => {
    if (otpCooldown <= 0) return;
    const timer = setInterval(() => {
      setOtpCooldown((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(timer);
  }, [otpCooldown]);

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

  const resetForm = () => {
    setError(null);
    setSuccessMsg(null);
    setOtpDigits(['', '', '', '', '', '']);
    setOtpCode('');
  };

  // 6-Digit OTP Handlers
  const handleOtpChange = (index: number, value: string) => {
    const cleanVal = value.replace(/\D/g, '');
    if (!cleanVal) {
      const newDigits = [...otpDigits];
      newDigits[index] = '';
      setOtpDigits(newDigits);
      setOtpCode(newDigits.join(''));
      return;
    }

    const digit = cleanVal.slice(-1);
    const newDigits = [...otpDigits];
    newDigits[index] = digit;
    setOtpDigits(newDigits);
    setOtpCode(newDigits.join(''));

    // Auto advance to next slot
    if (index < 5) {
      otpInputRefs.current[index + 1]?.focus();
    }
  };

  const handleOtpKeyDown = (
    index: number,
    e: React.KeyboardEvent<HTMLInputElement>
  ) => {
    if (e.key === 'Backspace') {
      if (!otpDigits[index] && index > 0) {
        const newDigits = [...otpDigits];
        newDigits[index - 1] = '';
        setOtpDigits(newDigits);
        setOtpCode(newDigits.join(''));
        otpInputRefs.current[index - 1]?.focus();
      } else {
        const newDigits = [...otpDigits];
        newDigits[index] = '';
        setOtpDigits(newDigits);
        setOtpCode(newDigits.join(''));
      }
    } else if (e.key === 'ArrowLeft' && index > 0) {
      e.preventDefault();
      otpInputRefs.current[index - 1]?.focus();
    } else if (e.key === 'ArrowRight' && index < 5) {
      e.preventDefault();
      otpInputRefs.current[index + 1]?.focus();
    }
  };

  const handleOtpPaste = (e: React.ClipboardEvent<HTMLDivElement>) => {
    e.preventDefault();
    const pastedText = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6);
    if (!pastedText) return;

    const newDigits = ['', '', '', '', '', ''];
    for (let i = 0; i < pastedText.length; i++) {
      newDigits[i] = pastedText[i];
    }
    setOtpDigits(newDigits);
    setOtpCode(pastedText);

    const targetIndex = Math.min(pastedText.length, 5);
    otpInputRefs.current[targetIndex]?.focus();
  };

  const validateEmail = (val: string): string | null => {
    const trimmed = val.trim();
    if (!trimmed) return 'Adresa de email este obligatorie.';
    if (!EMAIL_REGEX.test(trimmed)) return 'Adresa de email nu este validă.';
    return null;
  };

  const validatePassword = (val: string): string | null => {
    if (!val) return 'Parola este obligatorie.';
    if (val.length < PASSWORD_MIN)
      return `Parola trebuie să conțină cel puțin ${PASSWORD_MIN} caractere.`;
    return null;
  };

  const validateUsername = (val: string): string | null => {
    const trimmed = val.trim();
    if (!trimmed) return 'Numele de utilizator este obligatoriu.';
    if (trimmed.length < 2)
      return 'Numele de utilizator trebuie să aibă cel puțin 2 caractere.';
    if (trimmed.length > 24)
      return 'Numele de utilizator nu poate depăși 24 de caractere.';
    if (!USERNAME_REGEX.test(trimmed))
      return 'Numele poate conține doar litere, cifre, underscore, punct și cratimă.';
    return null;
  };

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    resetForm();

    const cleanInput = email.trim();
    if (!cleanInput) {
      setError('Introdu adresa de email sau numele de utilizator.');
      return;
    }

    if (cleanInput.includes('@')) {
      const emailErr = validateEmail(cleanInput);
      if (emailErr) {
        setError(emailErr);
        return;
      }
    } else {
      const userErr = validateUsername(cleanInput);
      if (userErr) {
        setError(userErr);
        return;
      }
    }

    const passErr = validatePassword(password);
    if (passErr) {
      setError(passErr);
      return;
    }

    setLoading(true);

    try {
      const { user, token, error: fbError } =
        await firebaseAuth.signInWithPassword(cleanInput.toLowerCase(), password);

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
    if (userErr) {
      setError(userErr);
      return;
    }
    const emailErr = validateEmail(cleanEmail);
    if (emailErr) {
      setError(emailErr);
      return;
    }
    const passErr = validatePassword(password);
    if (passErr) {
      setError(passErr);
      return;
    }
    if (password !== confirmPassword) {
      setError('Parolele introduse nu se potrivesc.');
      return;
    }

    setLoading(true);

    try {
      const { user, token, error: fbError } =
        await firebaseAuth.signUpWithPassword(
          cleanEmail,
          password,
          cleanUsername
        );

      if (fbError || !user || !token) {
        throw fbError || new Error('Eroare la crearea contului.');
      }

      localStorage.setItem('kurogane_token', token);
      localStorage.setItem('kurogane_user', JSON.stringify(user));
      window.dispatchEvent(new Event('kurogane_auth_changed'));
      onSuccess(user, token);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Eroare la crearea contului.');
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    resetForm();

    const cleanEmail = email.trim().toLowerCase();
    const emailErr = validateEmail(cleanEmail);
    if (emailErr) {
      setError(emailErr);
      return;
    }

    setLoading(true);

    try {
      const { success, error: fbError } =
        await firebaseAuth.sendPasswordResetEmail(cleanEmail);

      if (fbError || !success) {
        throw fbError || new Error('Eroare la trimiterea emailului de resetare.');
      }

      setSuccessMsg(
        `Un link de resetare a parolei a fost trimis la adresa ${cleanEmail}.`
      );
    } catch (err: any) {
      setError(err.message || 'Eroare la trimiterea email-ului de resetare.');
    } finally {
      setLoading(false);
    }
  };

  const handleSendResendOtp = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (otpCooldown > 0) return;
    setError(null);
    setSuccessMsg(null);

    const cleanEmail = email.trim().toLowerCase();
    const emailErr = validateEmail(cleanEmail);
    if (emailErr) {
      setError(emailErr);
      return;
    }

    setLoading(true);

    try {
      const res = await fetch(`${API_BASE_URL}/api/auth/send-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: cleanEmail }),
      });

      const data = await res.json();
      if (!res.ok) {
        if (data.waitSec) {
          setOtpCooldown(data.waitSec);
        }
        throw new Error(data.error || 'Eroare la trimiterea codului OTP.');
      }

      setOtpStep('VERIFY');
      setOtpCooldown(60); // 60s cooldown countdown
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
    if (
      !trimmedCode ||
      trimmedCode.length !== 6 ||
      !/^\d{6}$/.test(trimmedCode)
    ) {
      setError('Introdu un cod valid format din exact 6 cifre.');
      return;
    }

    setLoading(true);

    try {
      const res = await fetch(`${API_BASE_URL}/api/auth/verify-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: cleanEmail,
          code: trimmedCode,
          username,
        }),
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

  const handleGoogleLogin = async () => {
    try {
      resetForm();
      setLoading(true);

      const result = await firebaseAuth.signInWithGoogle();

      if (!result.error && !result.user) {
        setLoading(false);
        return;
      }

      if (result.error || !result.user || !result.token) {
        throw result.error || new Error('Eroare la conectarea cu Google.');
      }

      localStorage.setItem('kurogane_token', result.token);
      localStorage.setItem('kurogane_user', JSON.stringify(result.user));
      window.dispatchEvent(new Event('kurogane_auth_changed'));
      onSuccess(result.user, result.token);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Eroare la conectarea cu Google');
    } finally {
      setLoading(false);
    }
  };

  /** Spinner shown inside submit buttons while loading */
  const ButtonSpinner = () => <Loader2 className="w-4 h-4 animate-spin shrink-0" />;

  if (!isOpen) return null;

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
        className="bg-bgSurface border border-borderSubtle rounded-3xl w-full max-w-md p-6 sm:p-8 shadow-2xl relative overflow-hidden max-h-[92vh] overflow-y-auto overscroll-contain text-textPrimary text-left"
      >
        {/* Ambient Subtle Glow */}
        <div className="absolute -top-24 -right-24 w-60 h-60 bg-accentPrimary/15 rounded-full blur-3xl pointer-events-none" />

        {/* Close Button */}
        <button
          type="button"
          onClick={onClose}
          aria-label="Închide fereastra de autentificare"
          className="absolute top-4 right-4 w-9 h-9 rounded-full bg-bgPrimary hover:bg-bgSurfaceHover text-textSecondary hover:text-textPrimary flex items-center justify-center transition-colors border border-borderSubtle focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary cursor-pointer z-10"
        >
          <X className="w-4 h-4" />
        </button>

        {/* Top Header with Safe Margins from Close Button */}
        <div className="text-center mb-6 pt-1 px-8 sm:px-6">
          <h2
            id="auth-modal-title"
            className="text-xl sm:text-2xl font-bold text-textPrimary font-heading tracking-tight"
          >
            {mode === 'SIGN_IN' && 'Autentificare Cont'}
            {mode === 'SIGN_UP' && 'Creează un Cont Nou'}
            {mode === 'FORGOT_PASSWORD' && 'Resetare Parolă'}
            {mode === 'OTP_LOGIN' && 'Conectare cu Cod OTP'}
          </h2>
          <p className="text-xs text-textSecondary mt-1.5 max-w-xs mx-auto">
            {mode === 'SIGN_IN' &&
              'Introdu emailul și parola pentru a intra în profilul tău.'}
            {mode === 'SIGN_UP' &&
              'Alătură-te comunității Kurogane și colecționează serii anime/manga.'}
            {mode === 'FORGOT_PASSWORD' &&
              'Introdu emailul asociat contului tău pentru a primi linkul de resetare.'}
            {mode === 'OTP_LOGIN' &&
              (otpStep === 'VERIFY' ? (
                <span>
                  Codul a fost expediat la{' '}
                  <strong className="text-textPrimary font-semibold break-all">{email}</strong>
                </span>
              ) : (
                'Primește un cod securizat din 6 cifre pe email, fără parole.'
              ))}
          </p>
        </div>

        {/* Tabs switcher (Shown only for Login modes: Password vs OTP) */}
        {(mode === 'SIGN_IN' || (mode === 'OTP_LOGIN' && otpStep === 'SEND')) && (
          <div
            role="tablist"
            aria-label="Metodă de autentificare"
            className="grid grid-cols-2 p-1 bg-bgPrimary border border-borderSubtle rounded-full mb-5 text-xs font-bold"
          >
            {[
              { key: 'SIGN_IN', label: 'Parolă' },
              { key: 'OTP_LOGIN', label: 'Cod OTP' },
            ].map((tab) => (
              <button
                key={tab.key}
                role="tab"
                type="button"
                aria-selected={mode === tab.key}
                onClick={() => {
                  setMode(tab.key as AuthMode);
                  resetForm();
                }}
                className={`py-2 rounded-full transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary cursor-pointer ${
                  mode === tab.key
                    ? 'bg-accentPrimary text-white shadow-sm'
                    : 'text-textSecondary hover:text-textPrimary'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        )}

        {/* Feedback alerts */}
        {error && (
          <div
            ref={errorRef}
            tabIndex={-1}
            role="alert"
            aria-live="polite"
            className="mb-4 py-2 px-3.5 rounded-full bg-red-500/10 border border-red-500/25 text-red-400 text-xs flex items-center justify-center gap-2 focus:outline-none text-center"
          >
            <AlertCircle className="w-3.5 h-3.5 shrink-0" aria-hidden="true" />
            <span>{error}</span>
          </div>
        )}

        {successMsg && (
          <div
            role="status"
            aria-live="polite"
            className="mb-4 py-2 px-3.5 rounded-full bg-emerald-500/10 border border-emerald-500/25 text-emerald-400 text-xs flex items-center justify-center gap-2 text-center"
          >
            <CheckCircle2 className="w-3.5 h-3.5 shrink-0" aria-hidden="true" />
            <span>{successMsg}</span>
          </div>
        )}

        {/* SIGN IN FORM */}
        {mode === 'SIGN_IN' && (
          <form onSubmit={handleSignIn} className="space-y-3.5" noValidate>
            <div>
              <label
                htmlFor="signin-email"
                className="block text-xs text-textSecondary mb-1.5 font-semibold"
              >
                Email sau Nume de Utilizator
              </label>
              <div className="relative flex items-center">
                <User
                  className="w-4 h-4 text-textSecondary absolute left-3.5 pointer-events-none"
                  aria-hidden="true"
                />
                <input
                  ref={firstInputRef}
                  id="signin-email"
                  type="text"
                  name="username"
                  autoComplete="username"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="nume@domeniu.com sau username"
                  spellCheck={false}
                  className="h-11 w-full bg-bgPrimary border border-borderSubtle rounded-full pl-10 pr-4 text-xs sm:text-sm text-textPrimary placeholder:text-textMuted focus:outline-none focus:border-accentPrimary focus-visible:ring-2 focus-visible:ring-accentPrimary/20 transition-all"
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between items-center mb-1.5">
                <label
                  htmlFor="signin-password"
                  className="block text-xs text-textSecondary font-semibold"
                >
                  Parolă
                </label>
                <button
                  type="button"
                  onClick={() => {
                    setMode('FORGOT_PASSWORD');
                    resetForm();
                  }}
                  className="text-[11px] text-accentPrimary hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary rounded cursor-pointer"
                >
                  Ai uitat parola?
                </button>
              </div>
              <div className="relative flex items-center">
                <Lock
                  className="w-4 h-4 text-textSecondary absolute left-3.5 pointer-events-none"
                  aria-hidden="true"
                />
                <input
                  id="signin-password"
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="h-11 w-full bg-bgPrimary border border-borderSubtle rounded-full pl-10 pr-10 text-xs sm:text-sm text-textPrimary placeholder:text-textMuted focus:outline-none focus:border-accentPrimary focus-visible:ring-2 focus-visible:ring-accentPrimary/20 transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Ascunde parola' : 'Arată parola'}
                  className="absolute right-3 w-7 h-7 rounded-full flex items-center justify-center text-textSecondary hover:text-textPrimary hover:bg-bgSurfaceHover focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary transition-colors cursor-pointer"
                >
                  {showPassword ? (
                    <EyeOff className="w-4 h-4" />
                  ) : (
                    <Eye className="w-4 h-4" />
                  )}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="h-11 w-full rounded-full bg-accentPrimary hover:bg-accentPrimary/90 text-white font-bold text-xs shadow-md transition-all flex items-center justify-center gap-2 disabled:opacity-50 mt-3 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary active:scale-[0.98] cursor-pointer"
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
              <label
                htmlFor="signup-username"
                className="block text-xs text-textSecondary mb-1.5 font-semibold"
              >
                Nume Utilizator
              </label>
              <div className="relative flex items-center">
                <User
                  className="w-4 h-4 text-textSecondary absolute left-3.5 pointer-events-none"
                  aria-hidden="true"
                />
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
                  placeholder="Ex: OtakuMaster"
                  spellCheck={false}
                  className="h-11 w-full bg-bgPrimary border border-borderSubtle rounded-full pl-10 pr-4 text-xs sm:text-sm text-textPrimary placeholder:text-textMuted focus:outline-none focus:border-accentPrimary focus-visible:ring-2 focus-visible:ring-accentPrimary/20 transition-all"
                />
              </div>
            </div>

            <div>
              <label
                htmlFor="signup-email"
                className="block text-xs text-textSecondary mb-1.5 font-semibold"
              >
                Adresa de Email
              </label>
              <div className="relative flex items-center">
                <Mail
                  className="w-4 h-4 text-textSecondary absolute left-3.5 pointer-events-none"
                  aria-hidden="true"
                />
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
                  className="h-11 w-full bg-bgPrimary border border-borderSubtle rounded-full pl-10 pr-4 text-xs sm:text-sm text-textPrimary placeholder:text-textMuted focus:outline-none focus:border-accentPrimary focus-visible:ring-2 focus-visible:ring-accentPrimary/20 transition-all"
                />
              </div>
            </div>

            <div>
              <label
                htmlFor="signup-password"
                className="block text-xs text-textSecondary mb-1.5 font-semibold"
              >
                Parolă (min. 6 caractere)
              </label>
              <div className="relative flex items-center">
                <Lock
                  className="w-4 h-4 text-textSecondary absolute left-3.5 pointer-events-none"
                  aria-hidden="true"
                />
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
                  className="h-11 w-full bg-bgPrimary border border-borderSubtle rounded-full pl-10 pr-10 text-xs sm:text-sm text-textPrimary placeholder:text-textMuted focus:outline-none focus:border-accentPrimary focus-visible:ring-2 focus-visible:ring-accentPrimary/20 transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Ascunde parola' : 'Arată parola'}
                  className="absolute right-3 w-7 h-7 rounded-full flex items-center justify-center text-textSecondary hover:text-textPrimary hover:bg-bgSurfaceHover focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary transition-colors cursor-pointer"
                >
                  {showPassword ? (
                    <EyeOff className="w-4 h-4" />
                  ) : (
                    <Eye className="w-4 h-4" />
                  )}
                </button>
              </div>
            </div>

            <div>
              <label
                htmlFor="signup-confirm-password"
                className="block text-xs text-textSecondary mb-1.5 font-semibold"
              >
                Confirmă Parola
              </label>
              <div className="relative flex items-center">
                <Lock
                  className="w-4 h-4 text-textSecondary absolute left-3.5 pointer-events-none"
                  aria-hidden="true"
                />
                <input
                  id="signup-confirm-password"
                  type={showPassword ? 'text' : 'password'}
                  name="confirm-password"
                  autoComplete="new-password"
                  required
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  className="h-11 w-full bg-bgPrimary border border-borderSubtle rounded-full pl-10 pr-4 text-xs sm:text-sm text-textPrimary placeholder:text-textMuted focus:outline-none focus:border-accentPrimary focus-visible:ring-2 focus-visible:ring-accentPrimary/20 transition-all"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="h-11 w-full rounded-full bg-accentPrimary hover:bg-accentPrimary/90 text-white font-bold text-xs shadow-md transition-all flex items-center justify-center gap-2 disabled:opacity-50 mt-3 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary active:scale-[0.98] cursor-pointer"
            >
              {loading ? <ButtonSpinner /> : null}
              <span>Creează Cont Kurogane</span>
            </button>
          </form>
        )}

        {/* FORGOT PASSWORD FORM */}
        {mode === 'FORGOT_PASSWORD' && (
          <form onSubmit={handleForgotPassword} className="space-y-4" noValidate>
            <div>
              <label
                htmlFor="reset-email"
                className="block text-xs text-textSecondary mb-1.5 font-semibold"
              >
                Email-ul asociat contului tău
              </label>
              <div className="relative flex items-center">
                <Mail
                  className="w-4 h-4 text-textSecondary absolute left-3.5 pointer-events-none"
                  aria-hidden="true"
                />
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
                  className="h-11 w-full bg-bgPrimary border border-borderSubtle rounded-full pl-10 pr-4 text-xs sm:text-sm text-textPrimary placeholder:text-textMuted focus:outline-none focus:border-accentPrimary focus-visible:ring-2 focus-visible:ring-accentPrimary/20 transition-all"
                />
              </div>
            </div>

            <div className="flex items-center gap-2.5 pt-1">
              <button
                type="button"
                onClick={() => {
                  setMode('SIGN_IN');
                  resetForm();
                }}
                className="h-11 w-1/3 rounded-full bg-bgPrimary hover:bg-bgSurfaceHover text-textSecondary hover:text-textPrimary font-bold text-xs border border-borderSubtle transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary cursor-pointer"
              >
                Înapoi
              </button>
              <button
                type="submit"
                disabled={loading || !email.trim()}
                className="h-11 w-2/3 rounded-full bg-accentPrimary hover:bg-accentPrimary/90 text-white font-bold text-xs shadow-md transition-all flex items-center justify-center gap-2 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary active:scale-[0.98] cursor-pointer"
              >
                {loading ? <ButtonSpinner /> : null}
                <span>Trimite Link Resetare</span>
                {!loading && <KeyRound className="w-4 h-4" />}
              </button>
            </div>
          </form>
        )}

        {/* OTP LOGIN FORM */}
        {mode === 'OTP_LOGIN' && (
          <div className="space-y-4">
            {otpStep === 'SEND' ? (
              <form
                onSubmit={handleSendResendOtp}
                className="space-y-3.5"
                noValidate
              >
                <div>
                  <label
                    htmlFor="otp-email"
                    className="block text-xs text-textSecondary mb-1.5 font-semibold"
                  >
                    Adresa de Email pentru Cod OTP
                  </label>
                  <div className="relative flex items-center">
                    <Mail
                      className="w-4 h-4 text-textSecondary absolute left-3.5 pointer-events-none"
                      aria-hidden="true"
                    />
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
                      className="h-11 w-full bg-bgPrimary border border-borderSubtle rounded-full pl-10 pr-4 text-xs sm:text-sm text-textPrimary placeholder:text-textMuted focus:outline-none focus:border-accentPrimary focus-visible:ring-2 focus-visible:ring-accentPrimary/20 transition-all"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading || !email.trim() || otpCooldown > 0}
                  className="h-11 w-full rounded-full bg-accentPrimary hover:bg-accentPrimary/90 text-white font-bold text-xs shadow-md transition-all flex items-center justify-center gap-2 disabled:opacity-50 mt-3 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary active:scale-[0.98] cursor-pointer"
                >
                  {loading ? (
                    <ButtonSpinner />
                  ) : otpCooldown > 0 ? (
                    <>
                      <Clock className="w-4 h-4" />
                      <span>Retrimite codul în ({otpCooldown}s)</span>
                    </>
                  ) : (
                    <>
                      <span>Trimite Cod OTP pe Email</span>
                      <ArrowRight className="w-4 h-4" />
                    </>
                  )}
                </button>
              </form>
            ) : (
              <form
                onSubmit={handleVerifyResendOtp}
                className="space-y-4"
                noValidate
              >
                <div>
                  <label
                    className="block text-xs text-textSecondary mb-2 font-semibold text-center"
                  >
                    Introdu codul de 6 cifre primit pe email
                  </label>
                  
                  {/* 6-Digit Individual Slots */}
                  <div
                    className="flex items-center justify-center gap-2 sm:gap-2.5 my-3"
                    onPaste={handleOtpPaste}
                  >
                    {otpDigits.map((digit, idx) => (
                      <input
                        key={idx}
                        ref={(el) => {
                          otpInputRefs.current[idx] = el;
                        }}
                        id={`otp-digit-${idx}`}
                        type="text"
                        inputMode="numeric"
                        pattern="[0-9]*"
                        maxLength={1}
                        value={digit}
                        autoComplete={idx === 0 ? 'one-time-code' : 'off'}
                        onChange={(e) => handleOtpChange(idx, e.target.value)}
                        onKeyDown={(e) => handleOtpKeyDown(idx, e)}
                        className={`w-10 h-13 sm:w-11 sm:h-14 rounded-2xl bg-bgPrimary text-center text-xl sm:text-2xl font-mono font-bold text-textPrimary transition-all outline-none border cursor-text select-all ${
                          digit
                            ? 'border-accentPrimary bg-accentPrimary/5 ring-1 ring-accentPrimary/30 shadow-xs'
                            : 'border-borderSubtle focus:border-accentPrimary focus:ring-2 focus:ring-accentPrimary/20'
                        }`}
                      />
                    ))}
                  </div>
                </div>

                <div className="flex items-center justify-between text-xs px-1">
                  <span className="text-textSecondary">Nu ai primit codul?</span>
                  <button
                    type="button"
                    disabled={otpCooldown > 0 || loading}
                    onClick={() => handleSendResendOtp()}
                    className="text-accentPrimary font-semibold hover:underline disabled:opacity-50 flex items-center gap-1 cursor-pointer"
                  >
                    <RotateCcw className="w-3 h-3" />
                    <span>
                      {otpCooldown > 0
                        ? `Retrimite în ${otpCooldown}s`
                        : 'Retrimite Codul'}
                    </span>
                  </button>
                </div>

                <div className="flex items-center gap-2.5 pt-1">
                  <button
                    type="button"
                    onClick={() => {
                      setOtpStep('SEND');
                      setOtpCode('');
                      resetForm();
                    }}
                    className="h-11 w-1/3 rounded-full bg-bgPrimary hover:bg-bgSurfaceHover text-textSecondary hover:text-textPrimary font-bold text-xs border border-borderSubtle transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary cursor-pointer"
                  >
                    Înapoi
                  </button>
                  <button
                    type="submit"
                    disabled={loading || otpCode.trim().length !== 6}
                    className="h-11 w-2/3 rounded-full bg-accentPrimary hover:bg-accentPrimary/90 text-white font-bold text-xs shadow-md transition-all flex items-center justify-center gap-2 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary active:scale-[0.98] cursor-pointer"
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

        {/* Social OAuth Button (Google Only) */}
        {mode !== 'FORGOT_PASSWORD' && (
          <>
            <div className="relative my-5 text-center">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-borderSubtle" />
              </div>
              <span className="relative bg-bgSurface px-3 text-[11px] font-bold text-textSecondary uppercase tracking-wider">
                Sau
              </span>
            </div>

            <button
              type="button"
              disabled={loading}
              onClick={handleGoogleLogin}
              className="h-11 w-full rounded-full bg-bgPrimary hover:bg-bgSurfaceHover text-textPrimary font-bold text-xs flex items-center justify-center gap-2.5 border border-borderSubtle shadow-xs transition-all active:scale-[0.98] disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary cursor-pointer"
            >
              <svg
                className="w-4 h-4 shrink-0"
                viewBox="0 0 24 24"
                aria-hidden="true"
              >
                <path
                  fill="#4285F4"
                  d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17z"
                />
                <path
                  fill="#34A853"
                  d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.29v3.15C3.26 21.3 7.37 24 12 24z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.29c-.8 1.6-1.29 3.39-1.29 5.42s.49 3.82 1.29 5.42l3.99-3.15z"
                />
                <path
                  fill="#EA4335"
                  d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.37 0 3.26 2.7 1.29 6.58l3.99 3.15c.95-2.83 3.6-4.98 6.72-4.98z"
                />
              </svg>
              <span>Continuă cu Google</span>
            </button>
          </>
        )}

        {/* Toggle between Sign In / Sign Up modes */}
        {(mode === 'SIGN_IN' || mode === 'OTP_LOGIN') && (
          <p className="mt-5 text-center text-xs text-textSecondary">
            Nu ai cont?{' '}
            <button
              type="button"
              onClick={() => {
                setMode('SIGN_UP');
                resetForm();
              }}
              className="font-bold text-accentPrimary hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary rounded cursor-pointer"
            >
              Înregistrează-te
            </button>
          </p>
        )}

        {mode === 'SIGN_UP' && (
          <p className="mt-5 text-center text-xs text-textSecondary">
            Ai deja un cont?{' '}
            <button
              type="button"
              onClick={() => {
                setMode('SIGN_IN');
                resetForm();
              }}
              className="font-bold text-accentPrimary hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accentPrimary rounded cursor-pointer"
            >
              Conectează-te
            </button>
          </p>
        )}

        <div className="mt-6 text-center text-[10px] text-textSecondary border-t border-borderSubtle pt-4">
          Autentificarea este securizată prin Google Firebase Auth. Parolele sunt criptate și securizate.
        </div>
      </div>
    </div>
  );
}
