export const loader = 'postcss-loader';
export const options = {
    postcssOptions: {
        plugins: [
            require('tailwindcss'),
            require('autoprefixer'),
        ],
    },
};
