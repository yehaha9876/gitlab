export default {
  themeName: 'gl-white',
  monacoTheme: {
    base: 'vs',
    inherit: true,
    rules: [
      { token: 'comment', foreground: '999988', fontStyle: 'italic' },
      { token: 'comment.block.preprocessor', foreground: '999999' },
      { token: 'name', foreground: '333333' },
      { token: 'keyword', foreground: '2e2e2e', fontStyle: 'bold' },
      { token: 'operator', fontStyle: 'bold' },
      { token: 'constant', fontStyle: 'bold' },
      { token: 'number', foreground: '009999' },
      { token: 'string', foreground: 'dd1144' },
      { token: 'string.s', foreground: '990073' },
      { token: 'predefined.identifier', foreground: '008080' },
      { token: 'key.identifier', foreground: '008080' },
      { token: 'constructor.identifier', foreground: '445588', fontStyle: 'bold' },
      { token: 'namespace.instance.identifier', foreground: '008080' },
    ],
    colors: {
      'editor.foreground': '#2e2e2e',
      'editorLineNumber.foreground': '#CCCCCC',
    },
  },
};
