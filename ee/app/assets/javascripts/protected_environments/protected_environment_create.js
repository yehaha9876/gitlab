import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import AccessorUtilities from '~/lib/utils/accessor';
import Flash from '~/flash';
import CreateItemDropdown from '~/create_item_dropdown';
import AccessDropdown from 'ee/projects/settings/access_dropdown';
import { ACCESS_LEVELS, LEVEL_TYPES } from './constants';

export default class ProtectedEnvironmentCreate {
  constructor() {
    this.$form = $('.js-new-protected-environment');
    this.isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();
    this.currentProjectUserDefaults = {};
    this.buildDropdowns();
    this.$protectedInput = this.$form.find('input[name="protected_environment[name]"]');
    this.bindEvents();
  }

  bindEvents() {
    this.$form.on('submit', this.onFormSubmit.bind(this));
  }

  buildDropdowns() {
    const $allowedToDeployDropdown = this.$form.find('.js-allowed-to-deploy');

    // Cache callback
    this.onSelectCallback = this.onSelect.bind(this);

    // Allowed to Deploy dropdown
    this[`${ACCESS_LEVELS.DEPLOY}_dropdown`] = new AccessDropdown({
      $dropdown: $allowedToDeployDropdown,
      accessLevelsData: gon.deploy_access_levels,
      onSelect: this.onSelectCallback,
      accessLevel: ACCESS_LEVELS.DEPLOY,
    });

    this.createItemDropdown = new CreateItemDropdown({
      $dropdown: this.$form.find('.js-protected-environment-select'),
      defaultToggleLabel: 'Protected Environment',
      fieldName: 'protected_environment[name]',
      onSelect: this.onSelectCallback,
      getData: ProtectedEnvironmentCreate.getProtectedEnvironments,
    });
  }

  // Enable submit button after selecting an option
  onSelect() {
    const $allowedToDeploy = this[`${ACCESS_LEVELS.DEPLOY}_dropdown`].getSelectedItems();
    const toggle = !(
      this.$form.find('input[name="protected_environment[name]"]').val() &&
      $allowedToDeploy.length
    );

    this.$form.find('input[type="submit"]').attr('disabled', toggle);
  }

  static getProtectedEnvironments(term, callback) {
    callback(gon.open_environments);
  }

  getFormData() {
    const formData = {
      authenticity_token: this.$form.find('input[name="authenticity_token"]').val(),
      protected_environment: {
        name: this.$form.find('input[name="protected_environment[name]"]').val(),
      },
    };

    Object.keys(ACCESS_LEVELS).forEach(level => {
      const accessLevel = ACCESS_LEVELS[level];
      const selectedItems = this[`${accessLevel}_dropdown`].getSelectedItems();
      const levelAttributes = [];

      selectedItems.forEach(item => {
        if (item.type === LEVEL_TYPES.USER) {
          levelAttributes.push({
            user_id: item.user_id,
          });
        } else if (item.type === LEVEL_TYPES.ROLE) {
          levelAttributes.push({
            access_level: item.access_level,
          });
        } else if (item.type === LEVEL_TYPES.GROUP) {
          levelAttributes.push({
            group_id: item.group_id,
          });
        }
      });

      formData.protected_branch[`${accessLevel}_attributes`] = levelAttributes;
    });

    return formData;
  }

  onFormSubmit(e) {
    e.preventDefault();

    axios[this.$form.attr('method')](this.$form.attr('action'), this.getFormData())
      .then(() => {
        window.location.reload();
      })
      .catch(() => Flash('Failed to protect the environment'));
  }
}