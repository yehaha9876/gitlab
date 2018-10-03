import Vue from 'vue';
import Vuex from 'vuex';
import component from 'ee/security_dashboard/components/security_dashboard_table.vue';
import State from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

Vue.use(Vuex);
describe('Security Dashboard Table', () => {
  const vulnerabilities = [{ id: 0 }, { id: 1 }, { id: 2 }];
  const Component = Vue.extend(component);
  const initialState = State();
  let actions;
  let vm;

  beforeEach(() => {
    actions = {
      fetchVulnerabilities: jasmine.createSpy('fetchVulnerabilities'),
    };
  });

  afterEach(() => {
    actions.fetchVulnerabilities.calls.reset();
    vm.$destroy();
  });

  describe('data is loading', () => {
    beforeEach(() => {
      const state = { ...initialState, isLoadingVulnerabilities: true };
      const store = new Vuex.Store({
        modules: {
          vulnerabilities: { namespaced: true, state, actions },
        },
      });
      vm = mountComponentWithStore(Component, { store });
    });

    it('should render 10 skeleton rows in the table', () => {
      expect(vm.$el.querySelectorAll('.vulnerabilities-row')).toHaveLength(10);
    });
  });

  describe('data has loaded', () => {
    beforeEach(() => {
      const state = { ...initialState, vulnerabilities };
      const store = new Vuex.Store({
        modules: {
          vulnerabilities: { namespaced: true, state, actions },
        },
      });
      vm = mountComponentWithStore(Component, { store });
    });

    it('should dispatch a `fetchVulnerabilities` action on creation', () => {
      expect(actions.fetchVulnerabilities).toHaveBeenCalledTimes(1);
    });

    it('should render a row for each vulnerability', () => {
      expect(vm.$el.querySelectorAll('.vulnerabilities-row')).toHaveLength(vulnerabilities.length);
    });
  });
});
