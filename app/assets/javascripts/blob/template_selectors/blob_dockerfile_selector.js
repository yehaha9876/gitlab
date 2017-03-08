/* global Api */

const TemplateSelector = require('./template_selector');

class BlobDockerfileSelector extends TemplateSelector {
  requestFile(query) {
    return Api.dockerfileYml(query.name, (file, config) => this.setEditorContent(file, config));
  }
}

module.exports = BlobDockerfileSelector;
