// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const { generateWebpackConfig, merge } = require('shakapacker')
const path = require('path')

const webpackConfig = generateWebpackConfig()

const vueConfig = require('./loaders/vue')

const aliasConfig = {
  resolve: {
    alias: {
      pluginsDir: path.resolve(__dirname, '../../plugins/'),
      components: path.resolve(__dirname, '../../app/assets/javascripts/cinelartv/components/'),
      views: path.resolve(__dirname, '../../app/assets/javascripts/cinelartv/views/'),
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

module.exports = merge(vueConfig, sassLoaderConfig, customConfig, aliasConfig, options, webpackConfig)