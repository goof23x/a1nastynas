module.exports = {
  darkMode: 'class',
  content: [
    './index.html',
    './src/**/*.{vue,js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        tiffany: '#1de9b6', // Tiffany blue accent
      },
    },
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: [
      {
        a1nas: {
          'primary': '#1de9b6',
          'primary-focus': '#13bfa6',
          'primary-content': '#18181b',
          'base-100': '#18181b',
          'base-200': '#23232a',
          'neutral': '#23232a',
          'accent': '#1de9b6',
          'info': '#38bdf8',
          'success': '#22d3ee',
          'warning': '#fbbf24',
          'error': '#ef4444',
        },
      },
    ],
    darkTheme: 'a1nas',
  },
}; 