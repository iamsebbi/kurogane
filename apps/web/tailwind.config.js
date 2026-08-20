/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ['class', '[data-theme="dark"]'],
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        heading: ['var(--font-heading)', '"Zalando Sans Expanded"', 'sans-serif'],
        sans: ['var(--font-sans)', '"Google Sans"', 'sans-serif'],
      },
      colors: {
        bgPrimary: 'var(--bg-primary)',
        bgSurface: 'var(--bg-surface)',
        bgSurfaceHover: 'var(--bg-surface-hover)',
        accentPrimary: 'var(--accent-primary)',
        signalLive: 'var(--signal-live)',
        scoreGold: 'var(--score-gold)',
        badgeViolet: 'var(--badge-violet)',
        alertCoral: 'var(--alert-coral)',
        highlightEmber: 'var(--highlight-ember)',
        borderSubtle: 'var(--border-subtle)',
        textPrimary: 'var(--text-primary)',
        textSecondary: 'var(--text-secondary)',
        textMuted: 'var(--text-muted)',
      },
    },
  },
  plugins: [],
};
