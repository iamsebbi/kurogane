import './globals.css';
import type { Metadata } from 'next';
import Navbar from '../components/Navbar';
import ThemeToggle from '../components/ThemeToggle';

export const metadata: Metadata = {
  title: 'Kurogane — Modern Media Tracking Platform',
  description: 'Track Anime, Donghua, and Manga without rating manipulation or fragmented franchise orders.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <meta name="theme-color" content="#0f1419" />
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=5" />
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                try {
                  var saved = localStorage.getItem('kurogane-theme');
                  var theme = saved || 'dark';
                  document.documentElement.setAttribute('data-theme', theme);
                  if (theme === 'dark') {
                    document.documentElement.classList.add('dark');
                  } else {
                    document.documentElement.classList.remove('dark');
                  }
                } catch (e) {}
              })();
            `,
          }}
        />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Google+Sans:ital,opsz,wght@0,17..18,400..700;1,17..18,400..700&family=Zalando+Sans+Expanded:ital,wght@0,200..900;1,200..900&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="min-h-screen bg-bgPrimary text-textPrimary flex flex-col antialiased">
        <Navbar />
        <ThemeToggle />

        <main className="flex-1 pb-10">
          {children}
        </main>

        <footer className="border-t border-borderSubtle py-6 bg-bgSurface/50 text-center text-xs text-textMuted">
          <div className="max-w-6xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-2">
            <p>© 2026 Kurogane Media Tracking Platform. Open source & anti-review bombing technology.</p>
            <p className="text-textMuted">Local JSON Seed DB + AniList GraphQL API Integration</p>
          </div>
        </footer>
      </body>
    </html>
  );
}
