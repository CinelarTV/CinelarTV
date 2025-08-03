// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const { generateWebpackConfig, merge } = require('shakapacker')
const path = require('path')
const ForkTSCheckerWebpackPlugin = require("fork-ts-checker-webpack-plugin");


const webpackConfig = generateWebpackConfig({
  plugins: [new ForkTSCheckerWebpackPlugin()],
})

const vueConfig = require('./loaders/vue')



const aliasConfig = {
  resolve: {
    alias: {
      pluginsDir: path.resolve(__dirname, '../../plugins/'),
      components: path.resolve(__dirname, '../../app/assets/javascripts/cinelartv/components/'),
      views: path.resolve(__dirname, '../../app/assets/javascripts/cinelartv/views/'),
      models: path.resolve(__dirname, '../../app/assets/javascripts/cinelartv/app/models/'),
      '@': path.resolve(__dirname, '../../app/assets/javascripts/cinelartv/'),
      app: path.resolve(__dirname, '../../app/assets/javascripts/cinelartv/app/'),
      services: path.resolve(__dirname, '../../app/assets/javascripts/cinelartv/services/'),
    }
  }
}

const sassLoaderConfig = {
  module: {
    rules: [
      {
        test: /\.s[ac]ss$/i,
        use: [
          // Creates `style` nodes from JS strings
          "style-loader",
          // Translates CSS into CommonJS
          "css-loader",
          // Compiles Sass to CSS
          "sass-loader",
        ],
      },
    ],
  },
};

// for read .d.ts files

const rawLoaderConfig = {
  module: {
    rules: [
      {
        test: /\.d\.ts$/i,
        use: 'raw-loader',
      },
    ],
  },
};

const customConfig = {
  resolve: {
    extensions: ['.css']
  }
}
const options = {
  resolve: {
    extensions: ['.mjs', '.js', '.sass', ".scss", ".css", ".module.sass", ".module.scss", ".module.css", ".png", ".svg", ".gif", ".jpeg", ".jpg"]
  }
}

const postcssLoaderConfig = require('./loaders/postcss-loader');

module.exports = merge(
  vueConfig,
  sassLoaderConfig,
  postcssLoaderConfig,
  customConfig,
  aliasConfig,
  options,
  webpackConfig,
  rawLoaderConfig
)