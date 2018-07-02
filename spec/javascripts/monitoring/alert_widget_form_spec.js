import Vue from 'vue';
import AlertWidgetForm from 'ee/monitoring/components/alert_widget_form.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('AlertWidgetForm', () => {
  let AlertWidgetFormComponent;
  let vm;
  const props = {
    disabled: false,
    name: 'alert-name',
    query: 'e=mc2',
  };

  beforeAll(() => {
    AlertWidgetFormComponent = Vue.extend(AlertWidgetForm);
  });

  beforeEach(() => {
    setFixtures('<div id="alert-widget-form"></div>');
  });

  afterEach(() => {
    if (vm) vm.$destroy();
  });

  it('disables the input when disabled prop is set', () => {
    vm = mountComponent(
      AlertWidgetFormComponent,
      { ...props, disabled: true },
      '#alert-widget-form',
    );
    expect(vm.$refs.cancelButton).toBeDisabled();
    expect(vm.$refs.submitButton).toBeDisabled();
  });

  it('emits a "create" event when form submitted without existing alert', done => {
    vm = mountComponent(AlertWidgetFormComponent, props, '#alert-widget-form');
    expect(vm.$refs.submitButton.innerText).toBe('Add');
    vm.$on('create', alert => {
      expect(alert).toEqual({
        alert: null,
        name: props.name,
        query: props.query,
        operator: '<',
        threshold: 5,
      });
      done();
    });

    // the button should be disabled until an operator and threshold are selected
    expect(vm.$refs.submitButton).toBeDisabled();
    vm.operator = '<';
    vm.threshold = 5;
    Vue.nextTick(() => {
      vm.$refs.submitButton.click();
    });
  });

  it('emits a "delete" event when form submitted with existing alert and no changes are made', done => {
    vm = mountComponent(
      AlertWidgetFormComponent,
      {
        ...props,
        alert: 'alert',
        alertData: { operator: '<', threshold: 5 },
      },
      '#alert-widget-form',
    );

    vm.$on('delete', alert => {
      expect(alert).toEqual({
        alert: 'alert',
        name: props.name,
        query: props.query,
        operator: '<',
        threshold: 5,
      });
      done();
    });

    expect(vm.$refs.submitButton.innerText).toBe('Delete');
    vm.$refs.submitButton.click();
  });

  it('emits a "update" event when form submitted with existing alert', done => {
    vm = mountComponent(
      AlertWidgetFormComponent,
      {
        ...props,
        alert: 'alert',
        alertData: { operator: '<', threshold: 5 },
      },
      '#alert-widget-form',
    );
    expect(vm.$refs.submitButton.innerText).toBe('Delete');
    vm.$on('update', alert => {
      expect(alert).toEqual({
        alert: 'alert',
        name: props.name,
        query: props.query,
        operator: '=',
        threshold: 5,
      });
      done();
    });

    // change operator to allow update
    vm.operator = '=';
    Vue.nextTick(() => {
      expect(vm.$refs.submitButton.innerText).toBe('Save');
      vm.$refs.submitButton.click();
    });
  });
});
