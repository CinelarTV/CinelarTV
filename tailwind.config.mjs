import MiduAnimations from '@midudev/tailwind-animations';
/** @type {import('tailwindcss').Config} */
export default {
    content: [
        /* Rails + Vue + Vite */
        './app/views/**/*.{erb,html,slim}',
        './app/helpers/**/*.rb',
        './app/frontend/**/*.{js,vue,ts,jsx,tsx}',
        './app/frontend/components/**/*.{js,vue,ts,jsx,tsx}',
        './app/frontend/stylesheets/**/*.{css,scss}',
        './plugins/**/*.{js,vue,ts,jsx,tsx}',
    ],
    plugins: [require('vidstack/tailwind.cjs'), MiduAnimations],
}