/* global Api */

const TemplateSelector = require('./template_selector');

class BlobCiYamlSelector extends TemplateSelector {
  requestFile(query) {
    return Api.gitlabCiYml(query.name, (file, config) => this.setEditorContent(file, config));
  }
}

module.exports = BlobCiYamlSelector;
