'use strict';

var minify = require('html-minifier').minify;
var webpack = require('webpack');
var CompressionPlugin = require('compression-webpack-plugin');

var config = require('./webpack.base.config.js');

config.bail = true;
config.debug = false;
config.profile = false;
config.devtool = '#source-map';
config.output = {
  path: './dist',
  pathInfo: false,
  publicPath: '',
  filename: '[name].[hash].min.js',
  css: 'style.[hash].min.css',
  chunkFilename: '[id].js'
};
config.postcss = [
  // Optimizations
  require('postcss-import'),
  require('postcss-calc')()
].concat(config.postcss).concat([ // these need to run after the nested plugin
  require('csswring'),
  require('postcss-discard-duplicates')(),
]);
config.plugins = config.plugins.concat([
  new webpack.optimize.DedupePlugin(),
  new webpack.optimize.UglifyJsPlugin({
    mangle: {
      except: ['require', 'export', '$super']
    },
    compress: {
      warnings: false,
      sequences: true,
      dead_code: true,
      conditionals: true,
      booleans: true,
      unused: true,
      if_return: true,
      join_vars: true,
      drop_console: true
    }
  }),
  new CompressionPlugin({
    asset: '{file}.gz',
    algorithm: 'gzip',
    regExp: /\.js$|\.html$/,
    threshold: 10240,
    minRatio: 0.8
  })
]);

config.revFiles = function(data, files) {

  files.forEach(function(file) {
    var path = file.name.split('.');
    data = data.replace(path[0] + '.' + path[path.length - 1], file.name);
  });

  return minify(data, {
    collapseWhitespace: true,
    removeAttributeQuotes: true,
    useShortDoctype: true
  });
};

module.exports = config;
