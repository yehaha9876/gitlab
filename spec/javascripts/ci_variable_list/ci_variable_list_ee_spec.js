import $ from 'jquery';
import VariableList from '~/ci_variable_list/ci_variable_list';
import getSetTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';

describe('VariableList (EE features)', () => {
  preloadFixtures('projects/ci_cd_settings.html.raw');

  let $wrapper;
  let variableList;

  describe('with all inputs(key, value, protected, environment)', () => {
    beforeEach(() => {
      loadFixtures('projects/ci_cd_settings.html.raw');
      $wrapper = $('.js-ci-variable-list-section');

      variableList = new VariableList({
        container: $wrapper,
        formField: 'variables',
      });
      variableList.init();
    });

    describe('environment dropdown', () => {
      function addRowByNewEnvironment(newEnv) {
        const $row = $wrapper.find('.js-row:last-child');

        // // Open the dropdown
        $($row.find('.select2-container.js-variable-environment-trigger')).select2('val', newEnv).trigger('change.select2');
        $row.find('input.js-variable-environment-trigger')
          .val(newEnv)
          .trigger('input');

      }

      it('should add another row when editing the last rows environment dropdown', (done) => {
        addRowByNewEnvironment('someenv');

        getSetTimeoutPromise()
          .then(() => {
            expect($wrapper.find('.js-row').length).toBe(2);

            // Check for the correct default in the new row
            const $environmentInput = $wrapper.find('.js-row:last-child').find('input[name="variables[variables_attributes][][environment_scope]"]');
            expect($environmentInput.val()).toBe('*');
          })
          .then(done)
          .catch(done.fail);
      });

      it('should update dropdown with new environment values and remove values when row is removed', (done) => {
        addRowByNewEnvironment('someenv');

        const $row = $wrapper.find('.js-row:last-child');
        $row.find('.select2-container.js-variable-environment-trigger').select2('open');

        getSetTimeoutPromise()
          .then(() => {
            const $dropdownItemsBeforeRemove = $('#select2-drop .select2-result-selectable');
            expect($dropdownItemsBeforeRemove.length).toBe(2);
            expect($dropdownItemsBeforeRemove[0].textContent.trim()).toBe('someenv');
            expect($dropdownItemsBeforeRemove[1].textContent.trim()).toBe('* (All environments)');

            $row.find('.select2-container.js-variable-environment-trigger').select2('close');
            $row.prev().find('.js-row-remove-button').trigger('click');
          })
          .then(() => {
            $row.find('.select2-container.js-variable-environment-trigger').select2('open');
            const $dropdownItemsAfterRemove = $('#select2-drop .select2-result-selectable');
            expect($dropdownItemsAfterRemove.length).toBe(1);
            expect($dropdownItemsAfterRemove[0].textContent.trim()).toBe('* (All environments)');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
