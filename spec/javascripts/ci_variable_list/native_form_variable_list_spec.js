import NativeFormVariableList from '~/ci_variable_list/native_form_variable_list';

describe('NativeFormVariableList', () => {
  preloadFixtures('pipeline_schedules/edit.html.raw');

  let $wrapper;
  let variableList;

  beforeEach(() => {
    loadFixtures('pipeline_schedules/edit.html.raw');
    $wrapper = $('.js-ci-variable-list-section');

    variableList = new NativeFormVariableList({
      container: $wrapper,
      formField: 'schedule',
    });
    variableList.init();
  });

  describe('onFormSubmit', () => {
    it('should clear out the `name` attribute on the inputs for the last empty row on form submission (avoid BE validation)', () => {
      const $row = $wrapper.find('.js-row');
      expect($row.find('.js-ci-variable-input-key').attr('name')).toBe('schedule[variables_attributes][][key]');
      expect($row.find('.js-ci-variable-input-value').attr('name')).toBe('schedule[variables_attributes][][value]');

      variableList.onFormSubmit();

      expect($row.find('.js-ci-variable-input-key').attr('name')).toBe('');
      expect($row.find('.js-ci-variable-input-value').attr('name')).toBe('');
    });
  });
});
