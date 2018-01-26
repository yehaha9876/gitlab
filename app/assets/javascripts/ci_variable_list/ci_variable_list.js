import $ from 'jquery';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';
import { s__ } from '../locale';
import setupToggleButtons from '../toggle_buttons';
import CreateItemDropdown from '../create_item_dropdown';
import SecretValues from '../behaviors/secret_values';

function createEnvironmentItem(value) {
  return {
    title: value === '*' ? s__('CiVariable|All environments') : value,
    id: value,
    text: value,
  };
}

export default class VariableList {
  constructor({
    container,
    formField,
  }) {
    this.$container = $(container);
    this.formField = formField;
    this.environmentDropdownMap = new WeakMap();

    this.inputMap = {
      id: {
        selector: '.js-ci-variable-input-id',
        default: '',
      },
      key: {
        selector: '.js-ci-variable-input-key',
        default: '',
      },
      value: {
        selector: '.js-ci-variable-input-value',
        default: '',
      },
      protected: {
        selector: '.js-ci-variable-input-protected',
        default: 'true',
      },
      environment: {
        // We can't use a `.js-` class here because
        // gl_dropdown replaces the <input> and doesn't copy over the class
        // See https://gitlab.com/gitlab-org/gitlab-ce/issues/42458
        selector: `input[name="${this.formField}[variables_attributes][][environment]"]`,
        default: '*',
      },
      _destroy: {
        selector: '.js-ci-variable-input-destroy',
        default: '',
      },
    };

    this.secretValues = new SecretValues({
      container: this.$container[0],
      valueSelector: '.js-row:not(:last-child) .js-secret-value',
      placeholderSelector: '.js-row:not(:last-child) .js-secret-value-placeholder',
    });
  }

  init() {
    this.bindEvents();
    this.secretValues.init();
  }

  bindEvents() {
    this.$container.find('.js-row').each((index, rowEl) => {
      this.initRow(rowEl);
    });

    this.$container.on('click', '.js-row-remove-button', (e) => {
      const $row = $(e.currentTarget).closest('.js-row');
      this.removeRow($row);

      e.preventDefault();
    });

    const inputSelector = Object.keys(this.inputMap)
      .map(name => this.inputMap[name].selector)
      .join(',');

    // Remove any empty rows except the last row
    this.$container.on('blur', inputSelector, (e) => {
      const $row = $(e.currentTarget).closest('.js-row');

      const isTouched = this.checkIfRowTouched($row);
      if ($row.is(':not(:last-child)') && !isTouched) {
        this.removeRow($row);
      }
    });

    // Always make sure there is an empty last row
    this.$container.on('input trigger-change', inputSelector, () => {
      const $lastRow = this.$container.find('.js-row').last();

      const isTouched = this.checkIfRowTouched($lastRow);
      if (isTouched) {
        this.insertRow($lastRow);
      }
    });
  }

  initRow(rowEl) {
    const $row = $(rowEl);

    setupToggleButtons($row[0]);

    const $environmentSelect = $row.find('.js-variable-environment-toggle');
    if ($environmentSelect.length) {
      const createItemDropdown = new CreateItemDropdown({
        $dropdown: $environmentSelect,
        defaultToggleLabel: s__('CiVariable|All environments'),
        fieldName: `${this.formField}[variables_attributes][][environment]`,
        getData: (term, callback) => {
          const values = this.getEnvironmentValues();
          callback(values);
        },
        createNewItemFromValue: createEnvironmentItem,
        onSelect: () => {
          // Refresh the other dropdowns in the variable list
          // so they have the new value we just picked
          this.refreshDropdownData();

          $row.find(this.inputMap.environment.selector).trigger('trigger-change');
        },
      });

      // Clear out any data that might have been left-over from the row clone
      createItemDropdown.clearDropdown();

      this.environmentDropdownMap.set($row[0], createItemDropdown);
    }
  }

  insertRow($row) {
    const $rowClone = $row.clone();
    $rowClone.removeAttr('data-is-persisted');

    // Reset the inputs to their defaults
    Object.keys(this.inputMap).forEach((name) => {
      const entry = this.inputMap[name];
      $rowClone.find(entry.selector).val(entry.default);
    });

    this.initRow($rowClone);

    $row.after($rowClone);
  }

  removeRow($row) {
    const isPersisted = convertPermissionToBoolean($row.attr('data-is-persisted'));

    if (isPersisted) {
      $row.hide();
      $row
        // eslint-disable-next-line no-underscore-dangle
        .find(this.inputMap._destroy.selector)
        .val(true);
    } else {
      $row.remove();
    }
  }

  checkIfRowTouched($row) {
    return Object.keys(this.inputMap).some((name) => {
      const entry = this.inputMap[name];
      const $el = $row.find(entry.selector);
      return $el.length && $el.val() !== entry.default;
    });
  }

  getAllData() {
    // Ignore the last empty row because we don't want to try persist
    // a blank variable and run into validation problems.
    const validRows = this.$container.find('.js-row').toArray().slice(0, -1);

    return validRows.map((rowEl) => {
      const resultant = {};
      Object.keys(this.inputMap).forEach((name) => {
        const entry = this.inputMap[name];
        const $input = $(rowEl).find(entry.selector);
        if ($input.length) {
          resultant[name] = $input.val();
        }
      });

      return resultant;
    });
  }

  getEnvironmentValues() {
    const valueMap = {};
    this.$container.find(this.inputMap.environment.selector)
      .each((index, envInput) => {
        valueMap[envInput.value] = envInput.value;
      });

    return Object.keys(valueMap).map(createEnvironmentItem);
  }

  refreshDropdownData() {
    this.$container.find('.js-row').each((index, rowEl) => {
      const environmentDropdown = this.environmentDropdownMap.get(rowEl);
      environmentDropdown.refreshData();
    });
  }
}
