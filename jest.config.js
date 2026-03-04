const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        '^lightning/navigation$':
            '<rootDir>/jest-mocks/lightning/navigation/navigation.js'
    },
    modulePathIgnorePatterns: ['<rootDir>/.localdevserver']
};