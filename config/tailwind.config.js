module.exports = {
  content: [
    './app/views/**/*.{erb,haml,html,slim}',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
  ],
  theme: {
    extend: {
      fontFamily: {
        serif: ['Georgia', 'Cambria', '"Times New Roman"', 'Times', 'serif'],
      },
      typography: {
        stone: {
          css: {
            '--tw-prose-body': '#44403c',
            '--tw-prose-headings': '#1c1917',
          }
        }
      }
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
