import AUTH_METHOD_KEY from './constants';

export default class MirrorPull {
  constructor(formSelector) {
    this.$form = $(formSelector);
    this.$tabsContainer = this.$form.find('.js-auth-type');
  }

  init() {
    this.$form.on('submit', e => this.handleFormSubmit(e));
  }

  handleFormSubmit() {
    const authMethod = this.$tabsContainer.find('.active').data('auth-method');
    $('<input/>')
      .attr('type', 'hidden')
      .attr('name', AUTH_METHOD_KEY)
      .attr('value', authMethod)
      .appendTo(this.$form);
  }
}
