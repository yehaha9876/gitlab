/* global Api */

const TemplateSelector = require('./template_selector');

class BlobLicenseSelector extends TemplateSelector {
  requestFile(query) {
    const data = {
      project: this.dropdown.data('project'),
      fullname: this.dropdown.data('fullname'),
    };
    return Api.licenseText(query.id, data, (file, config) => this.setEditorContent(file, config));
  }
}

module.exports = BlobLicenseSelector;
