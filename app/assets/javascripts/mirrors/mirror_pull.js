/* global Flash */

import AUTH_METHOD from './constants';

export default class MirrorPull {
  constructor(formSelector) {
    this.backOffRequestCounter = 0;

    this.$form = $(formSelector);
    this.projectMirrorSSHEndpoint = this.$form.data('project-mirror-endpoint');
    this.projectMirrorAuthTypeEndpoint = this.$form.attr('action');

    this.$repositoryUrl = this.$form.find('.js-repo-url');
    this.$importDataIdEl = this.$form.find('.js-import-data-id');

    this.$sectionSSHHostKeys = this.$form.find('.js-ssh-host-keys-section');
    this.$hostKeysInformation = this.$form.find('.js-fingerprint-ssh-info');
    this.$btnDetectHostKeys = this.$form.find('.js-detect-host-keys');
    this.$btnSSHHostsAdvanced = this.$form.find('.js-ssh-hosts-advanced');
    this.$sshKnownHosts = this.$form.find('.js-known-hosts');
    this.$dropdownAuthType = this.$form.find('.js-pull-mirror-auth-type');

    this.$wellAuthTypeChanging = this.$form.find('.js-well-changing-auth');
    this.$wellPasswordAuth = this.$form.find('.js-well-password-auth');
    this.$wellSSHAuth = this.$form.find('.js-well-ssh-auth');
    this.$sshPublicKey = this.$form.find('.js-ssh-public-key');
  }

  init() {
    this.toggleAuthWell(this.$dropdownAuthType.val());

    this.$repositoryUrl.on('keyup', e => this.handleRepositoryUrlInput(e));
    this.$sshKnownHosts.on('keyup', e => this.handleSSHKnownHostsInput(e));
    this.$dropdownAuthType.on('change', e => this.handleAuthTypeChange(e));
    this.$btnDetectHostKeys.on('click', e => this.handleDetectHostKeys(e));
    this.$btnSSHHostsAdvanced.on('click', e => this.handleSSHHostsAdvanced(e));
  }

  handleRepositoryUrlInput() {
    const protocol = this.$repositoryUrl.val().split('://')[0];
    if (this.$form.get(0).checkValidity()) {
      this.$sectionSSHHostKeys.toggleClass('hidden', protocol !== 'ssh');
      this.$dropdownAuthType.find('.js-auth-type-ssh').toggleClass('hidden', /http/.test(protocol));
      if (/http/.test(protocol) &&
          this.$dropdownAuthType.val() !== AUTH_METHOD.PASSWORD) {
        this.$dropdownAuthType.val(AUTH_METHOD.PASSWORD);
        this.handleAuthTypeChange();
      }
    }
  }

  handleDetectHostKeys() {
    const repositoryUrl = this.$repositoryUrl.val();
    const $btnLoadSpinner = this.$btnDetectHostKeys.find('.detect-host-keys-load-spinner');

    this.$btnDetectHostKeys.disable();
    $btnLoadSpinner.removeClass('hidden');
    gl.utils.backOff((next, stop) => {
      $.getJSON(`${this.projectMirrorSSHEndpoint}?ssh_url=${repositoryUrl}`)
        .done((res, statusText, header) => {
          if (header.status === 204) {
            this.backOffRequestCounter = this.backOffRequestCounter += 1;
            if (this.backOffRequestCounter < 3) {
              next();
            } else {
              stop(res);
            }
          } else {
            stop(res);
          }
        })
        .fail(stop);
    })
    .then((res) => {
      $btnLoadSpinner.addClass('hidden');
      if (res.known_hosts && res.fingerprints) {
        this.showSSHInformation(res);
      }
    })
    .catch((res) => {
      const failureMessage = res.responseJSON ? res.responseJSON.message : 'Something went wrong on our end.';
      new Flash(failureMessage); // eslint-disable-line
      $btnLoadSpinner.addClass('hidden');
      this.$btnDetectHostKeys.enable();
    });
  }

  handleSSHKnownHostsInput() {
    this.$hostKeysInformation.find('.js-fingerprints-list').addClass('invalidate');
  }

  handleSSHHostsAdvanced() {
    const $knownHost = this.$sectionSSHHostKeys.find('.js-ssh-known-hosts');

    $knownHost.toggleClass('hidden');
    this.$btnSSHHostsAdvanced.toggleClass('show-advanced', $knownHost.hasClass('hidden'));
  }

  handleAuthTypeChange() {
    const selectedAuthType = this.$dropdownAuthType.val();
    const importDataId = this.$importDataIdEl.val();
    const authTypeData = {};

    if (importDataId) {
      authTypeData[this.$importDataIdEl.attr('name')] = importDataId;
    }

    authTypeData[this.$dropdownAuthType.attr('name')] = selectedAuthType;

    this.$wellAuthTypeChanging.removeClass('hidden');
    this.$wellPasswordAuth.addClass('hidden');
    this.$wellSSHAuth.addClass('hidden');
    $.ajax({
      type: 'PUT',
      url: this.projectMirrorAuthTypeEndpoint,
      dataType: 'json',
      data: authTypeData,
    })
    .done((res) => {
      if (selectedAuthType === AUTH_METHOD.SSH) {
        this.$sshPublicKey.text(res.import_data_attributes.ssh_public_key);
      }
      this.toggleAuthWell(selectedAuthType);
    })
    .always(() => {
      this.$wellAuthTypeChanging.addClass('hidden');
    });
  }

  showSSHInformation(sshHostKeys) {
    const $fingerprintsList = this.$hostKeysInformation.find('.js-fingerprints-list');
    let fingerprints = '';
    sshHostKeys.fingerprints.forEach((fingerprint) => {
      const escFingerprints = _.escape(fingerprint.fingerprint);
      fingerprints += `<code>${escFingerprints}</code>`;
    });

    this.$hostKeysInformation.removeClass('hidden');
    $fingerprintsList.removeClass('invalidate');
    $fingerprintsList.html(fingerprints);
    this.$hostKeysInformation.find('.js-known-hosts').val(sshHostKeys.known_hosts);
  }

  toggleAuthWell(authType) {
    this.$wellPasswordAuth.toggleClass('hidden', authType !== AUTH_METHOD.PASSWORD);
    this.$wellSSHAuth.toggleClass('hidden', authType !== AUTH_METHOD.SSH);
  }
}
