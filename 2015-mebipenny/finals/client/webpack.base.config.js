'use strict';

var webpack = require('webpack');

var postcssTools = require('webpack-postcss-tools');

var HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  target: 'web',
  entry: {
    javascript: './src/entry.jsx'
    //vendor: [ 'react' ]
  },
  output: {
    path: './dist',
    pathInfo: true,
    publicPath: '',
    filename: 'main.js',
    css: 'style.css'
  },
  module: {
    preLoaders: [
      {
        test: /\.jsx?$/,
        loader: 'eslint-loader', exclude: /node_modules/
      }
    ],
    loaders: [
      {
        test: /\.json$/,
        loader: 'json'
      },
      {
        test: /\.png$/,
        loader: 'url?mimetype=image/png'
      },
      {
        test: /\.gif$/,
        loader: 'url?mimetype=image/gif'
      },
      {
        test: /\.jpe?g$/,
        loader: 'url?mimetype=image/jpeg'
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'url?limit=10000&minetype=application/font-woff'
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'file'
      }
    ],
    noParse: /\.min\.js/
  },
  postcss: [
    // Plugins seem to be first in last out
    // https://github.com/postcss/postcss#plugins
    postcssTools.prependTildesToImports,

    // Fallbacks
    require('autoprefixer-core')({browsers: ['last 2 version']}),

    // Sass style nesting
    require('postcss-nested')(),

    // Future CSS Syntax
    require('postcss-custom-media')(),
    require('postcss-media-minmax')(),

    // config/vars
    require('postcss-simple-vars')({
      variables: function () {
        return require('./src/config/theme.json'); // global css variables
      }
    })
  ],
  resolve: {
    extentions: ['js', 'jsx', 'css']
  },
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify(process.env.NODE_ENV),
        PANDA_PUSH_APP_ID: JSON.stringify(process.env.PANDA_PUSH_APP_ID),
        PANDA_PUSH_BASE_URL: JSON.stringify(process.env.PANDA_PUSH_BASE_URL)
      }
    }),
    // new webpack.optimize.CommonsChunkPlugin('vendor.js', ['vendor']),
    new HtmlWebpackPlugin({
      template: 'src/index.html', // Load a custom template
      inject: 'body', // Inject all scripts into the body,
      filename: 'index.html'
    })
  ]
};
