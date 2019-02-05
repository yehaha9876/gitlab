import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import Alerts from 'ee/operations/components/dashboard/alerts.vue';

describe('alerts component', () => {
  const AlertsComponent = Vue.extend(Alerts);
  const mount = (props = {}) =>
    mountComponentWithStore(AlertsComponent, {
      props,
    });
  let vm;

  beforeEach(() => {
    vm = mount();
  });

  afterEach(() => {
    if (vm.$destroy) {
      vm.$destroy();
    }
  });

  it('renders multiple alert count when multiple alerts are present', () => {
    vm = mount({
      count: 2,
    });

    expect(vm.$el.querySelector('.js-alert-count').innerText.trim()).toBe('2 Alerts');
  });

  it('renders count for one alert when there is one alert', () => {
    vm = mount({
      count: 1,
    });

    expect(vm.$el.querySelector('.js-alert-count').innerText.trim()).toBe('1 Alert');
  });

  describe('wrapped components', () => {
    describe('icon', () => {
      it('renders warning', () => {
        expect(vm.$el.querySelector('.ic-warning')).not.toBe(null);
      });
    });
  });
});
