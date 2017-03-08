/* global Api */

const TemplateSelector = require('./template_selector');

class BlobGitignoreSelector extends TemplateSelector {
  requestFile(query) {
    return Api.gitignoreText(query.name, (file, config) => this.setEditorContent(file, config));
  }
}

module.exports = BlobGitignoreSelector;
