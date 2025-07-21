const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Exclude web-specific files and dependencies
config.resolver.platforms = ['ios', 'android', 'native'];

// Exclude web-specific files
config.resolver.blockList = [
  /.*\.web\.js$/,
  /.*\.web\.ts$/,
  /.*\.web\.tsx$/,
  /.*\.browser\.js$/,
  /.*\.browser\.ts$/,
  /.*\.browser\.tsx$/,
];

// Ensure only React Native compatible modules are included
config.resolver.alias = {
  ...config.resolver.alias,
  // Exclude web-specific modules
  'react-dom': false,
  'react-dom/server': false,
  'react-dom/client': false,
  'react-native-web': false,
};

// Add transformer to handle web-specific code
config.transformer.minifierConfig = {
  keep_fnames: true,
  mangle: {
    keep_fnames: true,
  },
};

// Disable file watching to prevent EMFILE errors
config.watchFolders = [];
config.resolver.watchFolders = [];

// Reduce file watching overhead
config.maxWorkers = 1;
config.resetCache = true;

module.exports = config; 