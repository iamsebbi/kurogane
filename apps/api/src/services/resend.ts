const RESEND_API_KEY = process.env.RESEND_API_KEY || process.env.NEXT_PUBLIC_RESEND_API_KEY || '';

const MAX_OTP_ATTEMPTS = 5;
const OTP_COOLDOWN_MS = 60 * 1000; // 1 minute between resends
const OTP_EXPIRY_MS = 10 * 60 * 1000; // 10 minutes

interface OtpEntry {
  code: string;
  expiresAt: number;
  attempts: number;
  lastSentAt: number;
}

export class ResendEmailService {
  private otpStore: Map<string, OtpEntry> = new Map();

  /**
   * Send a 6-digit OTP verification code via Resend
   */
  public async sendOtpEmail(toEmail: string): Promise<{ success: boolean; code?: string; message: string }> {
    const cleanEmail = toEmail.trim().toLowerCase();

    // Rate limit: prevent rapid-fire resends
    const existing = this.otpStore.get(cleanEmail);
    if (existing && Date.now() - existing.lastSentAt < OTP_COOLDOWN_MS) {
      const waitSec = Math.ceil((OTP_COOLDOWN_MS - (Date.now() - existing.lastSentAt)) / 1000);
      return {
        success: false,
        message: `Așteaptă ${waitSec} secunde înainte de a solicita un nou cod.`,
      };
    }

    // Generate cryptographically reasonable 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const now = Date.now();

    this.otpStore.set(cleanEmail, {
      code,
      expiresAt: now + OTP_EXPIRY_MS,
      attempts: 0,
      lastSentAt: now,
    });

    if (!RESEND_API_KEY || RESEND_API_KEY.includes('YOUR_RESEND_API_KEY')) {
      console.log(`\n[Resend Service - Demo Mode] 📧 OTP pentru ${cleanEmail}: [ ${code} ] (Valabil 10 min)\n`);
      return {
        success: true,
        code,
        message: `Codul de securitate a fost generat: ${code} (Setează RESEND_API_KEY în .env pentru trimitere pe email real)`,
      };
    }

    try {
      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'Kurogane Anime <onboarding@resend.dev>',
          to: [cleanEmail],
          subject: `🔐 Codul tău de securitate Kurogane`,
          html: `
            <div style="font-family: Arial, sans-serif; background-color: #0f172a; color: #f8fafc; padding: 32px; border-radius: 16px; max-width: 500px; margin: 0 auto;">
              <h2 style="color: #60a5fa; margin-top: 0;">⚔️ Kurogane Anime &amp; Manga</h2>
              <p style="font-size: 14px; color: #94a3b8;">Ai solicitat conectarea sau înregistrarea pe Kurogane.</p>
              <div style="background-color: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 16px; text-align: center; margin: 24px 0;">
                <span style="font-size: 12px; color: #94a3b8; display: block; margin-bottom: 8px;">CODUL TĂU UNIC DE VERIFICARE (OTP)</span>
                <span style="font-size: 32px; font-weight: bold; font-family: monospace; letter-spacing: 8px; color: #f59e0b;">${code}</span>
              </div>
              <p style="font-size: 12px; color: #64748b;">Codul este valabil timp de 10 minute. Dacă nu ai solicitat tu acest cod, poți ignora acest email.</p>
            </div>
          `,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        console.error('[Resend Error]:', data);
        return { success: false, message: data.message || 'Eroare la trimiterea emailului prin Resend.' };
      }

      console.log(`[Resend Service] Email trimis cu succes către ${cleanEmail} (ID: ${data.id})`);
      return { success: true, message: `Codul de verificare a fost trimis pe ${cleanEmail}.` };
    } catch (err: any) {
      console.error('[Resend Exception]:', err);
      return { success: false, message: err.message || 'Eroare de rețea la serviciul Resend.' };
    }
  }

  /**
   * Verify an OTP code submitted by user (with brute-force protection)
   */
  public verifyOtp(toEmail: string, submittedCode: string): { valid: boolean; error?: string } {
    const cleanEmail = toEmail.trim().toLowerCase();
    const entry = this.otpStore.get(cleanEmail);

    if (!entry) {
      return { valid: false, error: 'Nu a fost solicitat niciun cod pentru acest email. Solicită un cod nou.' };
    }

    if (Date.now() > entry.expiresAt) {
      this.otpStore.delete(cleanEmail);
      return { valid: false, error: 'Codul de verificare a expirat. Solicită un cod nou.' };
    }

    // Brute-force protection: max attempts
    if (entry.attempts >= MAX_OTP_ATTEMPTS) {
      this.otpStore.delete(cleanEmail);
      return { valid: false, error: 'Prea multe încercări eșuate. Solicită un cod nou.' };
    }

    entry.attempts++;

    if (entry.code === submittedCode.trim()) {
      this.otpStore.delete(cleanEmail);
      return { valid: true };
    }

    return { valid: false, error: `Cod incorect. Mai ai ${MAX_OTP_ATTEMPTS - entry.attempts} încercări.` };
  }
}

export const resendService = new ResendEmailService();
