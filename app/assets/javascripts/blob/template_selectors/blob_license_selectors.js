/* eslint-disable no-unused-vars, no-param-reassign */

const BlobLicenseSelector = require('./blob_license_selector');

class BlobLicenseSelectors {
  constructor({ $dropdowns, editor }) {
    this.$dropdowns = $dropdowns || $('.js-license-selector');
    this.initSelectors(editor);
  }

  initSelectors(editor) {
    this.$dropdowns.each((i, dropdown) => {
      const $dropdown = $(dropdown);

      return new BlobLicenseSelector({
        editor,
        pattern: /^(.+\/)?(licen[sc]e|copying)($|\.)/i,
        data: $dropdown.data('data'),
        wrapper: $dropdown.closest('.js-license-selector-wrap'),
        dropdown: $dropdown,
      });
    });
  }
}
module.exports = BlobLicenseSelectors;
