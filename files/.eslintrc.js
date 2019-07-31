module.exports = {
  env: {
    es6: true,
    node : true,
    browser: true,
    mocha: true,
  },
  parserOptions: {
    ecmaVersion: 2018,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
  },
  // https://github.com/google/eslint-config-google
  extends: "google",
  rules: {
    // https://eslint.org/docs/rules/

    // Possible Errors
    // https://eslint.org/docs/rules/#possible-errors

    // Best Practices
    // https://eslint.org/docs/rules/#best-practices

    // Strict Mode
    // https://eslint.org/docs/rules/#strict-mode

    // Variables
    // https://eslint.org/docs/rules/#variables
    'no-undef': 2,

    // Node.js and CommonJS
    // https://eslint.org/docs/rules/#nodejs-and-commonjs

    // Stylistic Issues
    // https://eslint.org/docs/rules/#stylistic-issues
    'indent': [2, 2],
    'max-len': [2, {
      code: 160,
      tabWidth: 2,
      ignoreUrls: true,
    }],
    'require-jsdoc': 0,
    // 'semi': [2, 'never'],

    // ECMAScript 6
    // https://eslint.org/docs/rules/#ecmascript-6

  },
}
