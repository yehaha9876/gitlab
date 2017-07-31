/* global Flash */

import AUTH_METHOD from './constants';

export default class MirrorPull {
  constructor(formSelector) {
    this.backOffRequestCounter = 0;

    this.$form = $(formSelector);
    this.projectMirrorSSHEndpoint = this.$form.data('project-mirror-endpoint');
    this.$repositoryUrl = this.$form.find('.js-repo-url');
    this.$fieldSSHHostKeys = this.$form.find('.js-ssh-host-keys');
    this.$btnDetectHostKeys = this.$form.find('.js-detect-host-keys');
    this.$dropdownAuthType = this.$form.find('.js-pull-mirror-auth-type');
    this.$wellPasswordAuth = this.$form.find('.js-well-password-auth');
    this.$wellSSHAuth = this.$form.find('.js-well-ssh-auth');
  }

  init() {
    this.toggleAuthWell(this.$dropdownAuthType.val());

    this.$repositoryUrl.on('keyup', e => this.handleRepositoryUrlInput(e));
    this.$dropdownAuthType.on('change', e => this.handleAuthTypeChange(e));
    this.$btnDetectHostKeys.on('click', e => this.handleDetectHostKeys(e));
  }

  handleRepositoryUrlInput() {
    const protocol = this.$repositoryUrl.val().split('://')[0];
    if (this.$form.get(0).checkValidity()) {
      this.$fieldSSHHostKeys.toggleClass('hidden', protocol !== 'ssh');
    }
  }

  handleDetectHostKeys() {
    const repositoryUrl = this.$repositoryUrl.val();
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
      // TODO show detected host keys on UI
    })
    .catch(res => new Flash(res.responseJSON.message));
  }

  handleAuthTypeChange(e) {
    const selectedAuthType = this.$dropdownAuthType.val();
    this.toggleAuthWell(selectedAuthType);
  }

  toggleAuthWell(authType) {
    this.$wellPasswordAuth.toggleClass('hidden', authType !== AUTH_METHOD.PASSWORD);
    this.$wellSSHAuth.toggleClass('hidden', authType !== AUTH_METHOD.SSH);
  }
}
