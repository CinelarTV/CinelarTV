// PostCSS loader para Tailwind CSS v4 y Webpack
module.exports = {
    module: {
        rules: [
            {
                test: /\.css$/i,
                use: [
                    'style-loader',
                    'css-loader',
                    require.resolve('./postcss'),
                ],
            },
        ],
    },
};
