module.exports = {
  env: {
    es6: true,
    node: true,
    browser: true,
  },
  parserOptions: {
    ecmaVersion: 2018,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
  },
  // https://github.com/google/eslint-config-google
  extends: ['google', 'prettier', 'plugin:prettier/recommended'],
  plugins: ['prettier'],
  rules: {
    'no-undef': 2,
    indent: [2, 2],
    'max-len': [
      2,
      {
        code: 160,
        tabWidth: 2,
        ignoreUrls: true,
      },
    ],
    'require-jsdoc': 0,
  },
}
