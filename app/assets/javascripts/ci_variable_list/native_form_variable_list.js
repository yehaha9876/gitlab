import VariableList from './ci_variable_list';

// Used for the variable list on scheduled pipeline edit page
export default class NativeFormVariableList {
  constructor({
    container,
    formField = 'variables',
  }) {
    this.$container = $(container);

    this.variableList = new VariableList({
      container: this.$container,
      formField,
    });
  }

  init() {
    this.bindEvents();
    this.variableList.init();
  }

  bindEvents() {
    this.$container.closest('form').on('submit', this.onFormSubmit.bind(this));
  }

  // Clear out the names in the empty last row so it
  // doesn't get submitted and throw validation errors
  onFormSubmit() {
    const $lastRow = this.$container.find('.js-row').last();

    const isTouched = this.variableList.checkIfRowTouched($lastRow);
    if (!isTouched) {
      $lastRow.find('input, textarea').attr('name', '');
    }
  }
}
