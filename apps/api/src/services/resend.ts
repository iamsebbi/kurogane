import crypto from 'crypto';

const RESEND_API_KEY = process.env.RESEND_API_KEY || process.env.NEXT_PUBLIC_RESEND_API_KEY || '';

const MAX_OTP_ATTEMPTS = 5;
const OTP_COOLDOWN_MS = 60 * 1000; // 1 minute between resends
const OTP_EXPIRY_MS = 10 * 60 * 1000; // 10 minutes
const MAX_HOURLY_REQUESTS = 5;
const OTP_SALT = process.env.OTP_SALT || 'kurogane_otp_security_salt_2026';

interface OtpEntry {
  codeHash: string;
  expiresAt: number;
  attempts: number;
  lastSentAt: number;
  hourlyRequests: number[];
}

export class ResendEmailService {
  private otpStore: Map<string, OtpEntry> = new Map();

  private hashCode(code: string, email: string): string {
    return crypto
      .createHash('sha256')
      .update(`${email}:${code}:${OTP_SALT}`)
      .digest('hex');
  }

  /**
   * Send a 6-digit OTP verification code via Resend
   */
  public async sendOtpEmail(toEmail: string): Promise<{ success: boolean; code?: string; message: string }> {
    const cleanEmail = toEmail.trim().toLowerCase();
    const now = Date.now();

    const existing = this.otpStore.get(cleanEmail);

    // 1. Hourly rate limit check (max 5 requests per hour)
    if (existing) {
      const oneHourAgo = now - 60 * 60 * 1000;
      const recentRequests = existing.hourlyRequests.filter((ts) => ts > oneHourAgo);
      if (recentRequests.length >= MAX_HOURLY_REQUESTS) {
        return {
          success: false,
          message: 'Ai depășit limita de 5 coduri pe oră. Te rugăm să încerci mai târziu.',
        };
      }

      // 2. Cooldown check (60s between requests)
      if (now - existing.lastSentAt < OTP_COOLDOWN_MS) {
        const waitSec = Math.ceil((OTP_COOLDOWN_MS - (now - existing.lastSentAt)) / 1000);
        return {
          success: false,
          waitSec,
          message: `Așteaptă ${waitSec} secunde înainte de a solicita un nou cod.`,
        };
      }
    }

    // Generate cryptographically secure 6-digit code
    const code = crypto.randomInt(100000, 1000000).toString();
    const codeHash = this.hashCode(code, cleanEmail);

    const hourlyRequests = existing
      ? [...existing.hourlyRequests.filter((ts) => ts > now - 60 * 60 * 1000), now]
      : [now];

    this.otpStore.set(cleanEmail, {
      codeHash,
      expiresAt: now + OTP_EXPIRY_MS,
      attempts: 0,
      lastSentAt: now,
      hourlyRequests,
    });

    const apiKey = process.env.RESEND_API_KEY || process.env.NEXT_PUBLIC_RESEND_API_KEY || '';

    if (!apiKey || apiKey.includes('YOUR_RESEND_API_KEY')) {
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
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'Kurogane <onboarding@resend.dev>',
          to: [cleanEmail],
          subject: 'Cod de autentificare Kurogane',
          html: `
            <!DOCTYPE html>
            <html lang="ro">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>Cod de autentificare Kurogane</title>
              <link rel="preconnect" href="https://fonts.googleapis.com">
              <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
              <link href="https://fonts.googleapis.com/css2?family=Google+Sans:ital,opsz,wght@0,17..18,400..700;1,17..18,400..700&family=Zalando+Sans+Expanded:ital,wght@0,200..900;1,200..900&display=swap" rel="stylesheet">
              <style>
                @import url('https://fonts.googleapis.com/css2?family=Google+Sans:ital,opsz,wght@0,17..18,400..700;1,17..18,400..700&family=Zalando+Sans+Expanded:ital,wght@0,200..900;1,200..900&display=swap');
                .font-heading {
                  font-family: 'Zalando Sans Expanded', 'Google Sans', -apple-system, BlinkMacSystemFont, sans-serif !important;
                }
                .font-sans {
                  font-family: 'Google Sans', -apple-system, BlinkMacSystemFont, Roboto, sans-serif !important;
                }
              </style>
            </head>
            <body style="margin: 0; padding: 0; background-color: #0b0f19; font-family: 'Google Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #0b0f19; padding: 40px 16px;">
                <tr>
                  <td align="center">
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 480px; background-color: #111726; border: 1px solid #1e293b; border-radius: 24px; overflow: hidden; box-shadow: 0 20px 40px -15px rgba(0, 0, 0, 0.6);">
                      
                      <!-- Header Accent Bar -->
                      <tr>
                        <td height="4" style="background: linear-gradient(90deg, #6366f1 0%, #8b5cf6 50%, #ec4899 100%); line-height: 4px; font-size: 4px;">&nbsp;</td>
                      </tr>

                      <!-- Card Content -->
                      <tr>
                        <td style="padding: 40px 32px; text-align: center;">
                          
                          <!-- Wordmark (Zalando Sans Expanded) -->
                          <div class="font-heading" style="font-family: 'Zalando Sans Expanded', 'Google Sans', -apple-system, sans-serif; font-size: 22px; font-weight: 800; letter-spacing: 3px; text-transform: uppercase; color: #ffffff; margin-bottom: 24px;">
                            KUROGANE
                          </div>

                          <!-- Title & Subtitle -->
                          <h1 class="font-heading" style="font-family: 'Zalando Sans Expanded', 'Google Sans', -apple-system, sans-serif; font-size: 22px; font-weight: 700; color: #f8fafc; margin: 0 0 10px 0; letter-spacing: -0.02em;">
                            Codul tău de conectare
                          </h1>
                          <p class="font-sans" style="font-family: 'Google Sans', -apple-system, sans-serif; font-size: 13px; line-height: 1.6; color: #94a3b8; margin: 0 0 28px 0;">
                            Folosește codul de securitate de mai jos pentru a finaliza autentificarea în contul tău.
                          </p>

                          <!-- Code Box -->
                          <div style="background-color: #172033; border: 1px solid #29354d; border-radius: 16px; padding: 22px 16px; margin: 0 0 24px 0;">
                            <span class="font-sans" style="font-family: 'Google Sans', -apple-system, sans-serif; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 2px; color: #818cf8; display: block; margin-bottom: 8px;">
                              Cod Unic de Securitate
                            </span>
                            <span style="font-size: 36px; font-weight: 800; font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Courier New', monospace; letter-spacing: 8px; color: #ffffff; display: block; line-height: 1.1;">
                              ${code}
                            </span>
                          </div>

                          <!-- Expiry Note -->
                          <p class="font-sans" style="font-family: 'Google Sans', -apple-system, sans-serif; font-size: 12px; color: #64748b; margin: 0 0 28px 0; line-height: 1.5;">
                            Codul expiră în <strong>10 minute</strong>.<br>Nu partaja acest cod cu altcineva.
                          </p>

                          <!-- Divider -->
                          <div style="height: 1px; background-color: #1e293b; margin: 0 0 24px 0;"></div>

                          <!-- Footer Disclaimer -->
                          <p class="font-sans" style="font-family: 'Google Sans', -apple-system, sans-serif; font-size: 11px; color: #475569; line-height: 1.5; margin: 0;">
                            Dacă nu ai solicitat tu acest cod, poți ignora în siguranță acest email. Contul tău rămâne complet protejat.
                          </p>

                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </body>
            </html>
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
   * Verify an OTP code submitted by user (with brute-force protection and hash comparison)
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

    const submittedHash = this.hashCode(submittedCode.trim(), cleanEmail);

    if (entry.codeHash === submittedHash) {
      this.otpStore.delete(cleanEmail);
      return { valid: true };
    }

    return { valid: false, error: `Cod incorect. Mai ai ${MAX_OTP_ATTEMPTS - entry.attempts} încercări.` };
  }
}

export const resendService = new ResendEmailService();
