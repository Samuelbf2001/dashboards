import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        cream: {
          DEFAULT: '#FAF7F2',
          light: '#F5F0E8',
          dark: '#EDE7DB',
        },
        navy: {
          DEFAULT: '#1E2A4A',
          light: '#2D3E6E',
          lighter: '#3D5490',
          dark: '#141D34',
        },
        teal: {
          DEFAULT: '#2A9D8F',
          light: '#3BBDAE',
          dark: '#1E7268',
        },
        warm: {
          DEFAULT: '#8B8677',
          light: '#B5B0A8',
          lighter: '#D4CFC8',
        },
      },
      fontFamily: {
        poppins: ['var(--font-poppins)', 'sans-serif'],
        lato: ['var(--font-lato)', 'sans-serif'],
      },
      boxShadow: {
        card: '0 1px 3px 0 rgba(30,42,74,0.08), 0 1px 2px -1px rgba(30,42,74,0.06)',
        'card-hover': '0 4px 12px 0 rgba(30,42,74,0.12), 0 2px 4px -1px rgba(30,42,74,0.08)',
      },
    },
  },
  plugins: [],
}

export default config
