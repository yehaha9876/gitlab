import $ from 'jquery';
import 'autocomplete.js/index_jquery';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';
import { s__ } from '../locale';
import setupToggleButtons from '../toggle_buttons';
import SecretValues from '../behaviors/secret_values';

const ALL_ENVIRONMENTS_STRING = s__('CiVariable|All environments');
const SCOPE_DOC_LINK = $('.js-ci-variable-list-section').data('scopeDocsLink');

function createEnvironmentItem(value) {
  const hint = value.match(/("([^"]|"")*")/);
  const item = hint ? value.replace(/"/g, '') : value;

  return {
    title: item === '*' ? ALL_ENVIRONMENTS_STRING : item,
    id: item,
    text: item === '*' ? s__('CiVariable|* (All environments)') : item,
    hint,
  };
}

function wrapHint(suggestion, text) {
  if (suggestion.hint) return `"${text}"`;
  return text;
}

export default class VariableList {
  constructor({ container, formField }) {
    this.$container = $(container);
    this.formField = formField;
    this.environmentDropdownMap = new WeakMap();
    this.$rowClone = null;

    this.inputMap = {
      id: {
        selector: '.js-ci-variable-input-id',
        default: '',
      },
      key: {
        selector: '.js-ci-variable-input-key',
        default: '',
      },
      secret_value: {
        selector: '.js-ci-variable-input-value',
        default: '',
      },
      protected: {
        selector: '.js-ci-variable-input-protected',
        default: 'false',
      },
      environment_scope: {
        // We can't use a `.js-` class here because
        // gl_dropdown replaces the <input> and doesn't copy over the class
        // See https://gitlab.com/gitlab-org/gitlab-ce/issues/42458
        selector: `input[name="${this.formField}[variables_attributes][][environment_scope]"]`,
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
    this.$rowClone = this.$container.find('.js-row').last().clone();
    this.bindEvents();
    this.secretValues.init();
  }

  bindEvents() {
    this.$container.find('.js-row').each((index, rowEl) => {
      this.initRow(rowEl);
    });

    this.$container.on('click', '.js-row-remove-button', e => {
      e.preventDefault();
      this.removeRow($(e.currentTarget).closest('.js-row'));
    });

    const inputSelector = Object.keys(this.inputMap)
      .map(name => this.inputMap[name].selector)
      .join(',');

    // Remove any empty rows except the last row
    this.$container.on('blur', inputSelector, (e) => {
      const $row = $(e.currentTarget).closest('.js-row');

      if ($row.is(':not(:last-child)') && !this.checkIfRowTouched($row)) {
        this.removeRow($row);
      }
    });

    // Always make sure there is an empty last row
    this.$container.on('input trigger-change change autocomplete:selected', inputSelector, () => {
      const $lastRow = this.$container.find('.js-row').last();

      if (this.checkIfRowTouched($lastRow)) {
        this.insertRow($lastRow);
      }
    });

    // Always ensure only one dropdown is open
    this.$container.on('autocomplete:opened autocomplete:updated', inputSelector, (e) => {
      $(this.inputMap.environment_scope.selector).not($(e.target)).each((index, $el) => {
        $($el).autocomplete('close');
      });
    });

    // Ensure content stays the same when cycling through options
    this.$container.on('autocomplete:cursorchanged', inputSelector, (e) => {
      $(e.target).val($(e.target).autocomplete('val'));
    });

    // Refresh dropdown when opened
    this.$container.on('autocomplete:opened', inputSelector, (e) => {
      const val = $(e.target).autocomplete('val');
      $(e.target).autocomplete('val', '').autocomplete('val', val);
    });
  }

  initRow(rowEl) {
    const $row = $(rowEl);

    setupToggleButtons($row[0]);

    // Reset the resizable textarea
    $row.find(this.inputMap.secret_value.selector).css('height', '');

    const $environmentSelect = $row.find('.js-variable-environment-trigger');
    if ($environmentSelect.length) {
      const dropdownTrigger = $row.find(this.inputMap.environment_scope.selector);
      let searchTerm = '';

      $(dropdownTrigger).autocomplete({
        hint: false,
        minLength: 0,
        autoselect: false,
        autoselectOnBlur: false,
        openOnFocus: true,
        templates: {
          header: `<span class="dropdown-header ci-variable-environment-help-text">
                Enter scope (wildcards allowed) or select a past value. <a target="_blank" rel="noopener noreferrer" href="${SCOPE_DOC_LINK}">Learn more</a></span>`,
        },
        cssClasses: {
          root: 'dropdown',
          cursor: 'active',
          noPrefix: true,
          dropdownMenu: 'dropdown-menu',
          suggestions: 'dropdown-content',
          suggestion: 'dropdown-item',
        },
      }, [{
        source: (q, cb) => {
          searchTerm = q;
          if (!q || q === '*') {
            const results = this.getEnvironmentValues();
            if (!results.some((item) => item.id === '*')) results.push(createEnvironmentItem('*'));
            return cb(results);
          }

          return cb(fuzzaldrinPlus.filter(this.getEnvironmentValues(), q, { key: 'text' }));
        },
        templates: {
          suggestion: item => `<span class="menu-item" role="button">${wrapHint(item, VariableList.highlightTextMatches(item.text, searchTerm))}</span>`,
        },
        minLength: 0,
        displayKey: suggestion => ((suggestion.title === ALL_ENVIRONMENTS_STRING) ? '*' : suggestion.text),
      }]);

      this.environmentDropdownMap.set($row[0], $(dropdownTrigger));
    }
  }

  static highlightTextMatches(text, term) {
    const occurrences = fuzzaldrinPlus.match(text, term);
    const { indexOf } = [];
    return [...text].map((character, i) => ((indexOf.call(occurrences, i) !== -1) ? `<b>${character}</b>` : character)).join('');
  }

  insertRow($row) {
    const $rowClone = this.$rowClone.clone();
    $rowClone.removeAttr('data-is-persisted');

    // Reset the inputs to their defaults
    Object.keys(this.inputMap).forEach(name => {
      const entry = this.inputMap[name];
      $rowClone.find(entry.selector).val(entry.default);
    });

    $row.after($rowClone);

    this.initRow($rowClone);
  }

  removeRow(row) {
    const $row = $(row);
    const isPersisted = convertPermissionToBoolean($row.attr('data-is-persisted'));

    $row.find(this.inputMap.environment_scope.selector).autocomplete('destroy');

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
    return Object.keys(this.inputMap).some(name => {
      const entry = this.inputMap[name];
      const $el = $row.find(entry.selector);
      return $el.length && $el.val() !== entry.default;
    });
  }

  toggleEnableRow(isEnabled = true) {
    this.$container.find(this.inputMap.key.selector).attr('disabled', !isEnabled);
    this.$container.find('.js-row-remove-button').attr('disabled', !isEnabled);
  }

  hideValues() {
    this.secretValues.updateDom(false);
  }

  getAllData() {
    // Ignore the last empty row because we don't want to try persist
    // a blank variable and run into validation problems.
    const validRows = this.$container
      .find('.js-row')
      .toArray()
      .slice(0, -1);

    return validRows.map(rowEl => {
      const resultant = {};
      Object.keys(this.inputMap).forEach(name => {
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
    const valueMap = this.$container
      .find(this.inputMap.environment_scope.selector)
      .toArray()
      .filter(input => input.value)
      .reduce(
        (prevValueMap, envInput) => ({
          ...prevValueMap,
          [envInput.value]: (envInput.value !== '*' && document.activeElement === envInput) ? `"${envInput.value}"` : envInput.value,
        }),
        {},
      );

    return Object.values(valueMap).map(createEnvironmentItem).reverse();
  }
}
