const parser = require('@typescript-eslint/parser'); const plugin=require('@typescript-eslint/eslint-plugin');
module.exports = [{files:['**/*.{ts,tsx}'],languageOptions:{parser,parserOptions:{ecmaFeatures:{jsx:true}}},plugins:{'@typescript-eslint':plugin},rules:{'no-unused-vars':'off','@typescript-eslint/no-unused-vars':'error'}}];
