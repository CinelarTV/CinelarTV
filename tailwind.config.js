import miduAnimations from "@midudev/tailwind-animations"
const colors = require('tailwindcss/colors')


/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/javascripts/cinelartv/**/*.vue',
    './app/frontend/**/*.{js,ts,vue,jsx,tsx}',
    './app/frontend/cinelartv-legacy/**/*.vue',
    './app/javascripts/**/*.js',
    './app/assets/stylesheets/**/*.css',
  ],
  theme: {
    extend: {
      colors: {
        ...colors
      }
    },
  },
  plugins: [
    miduAnimations
  ],
}

