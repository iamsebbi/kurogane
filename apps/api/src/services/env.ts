import fs from 'fs';
import path from 'path';

export function loadEnvironment(): void {
  [
    path.join(__dirname, '../../.env'),
    path.join(__dirname, '../../../.env'),
    path.join(process.cwd(), '.env'),
    path.join(process.cwd(), 'apps/api/.env'),
  ].forEach((envPath) => {
    if (fs.existsSync(envPath)) {
      try {
        const content = fs.readFileSync(envPath, 'utf-8');
        content.split('\n').forEach((line) => {
          const trimmed = line.trim();
          if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
            const idx = trimmed.indexOf('=');
            const key = trimmed.substring(0, idx).trim();
            const val = trimmed.substring(idx + 1).trim();
            if (key && !process.env[key]) {
              process.env[key] = val.replace(/^["']|["']$/g, '');
            }
          }
        });
      } catch (e) {}
    }
  });
}

// Automatically load on import
loadEnvironment();
