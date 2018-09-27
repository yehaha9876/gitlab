import Vue from 'vue';
import Vuex from 'vuex';
import component from 'ee/security_dashboard/components/security_dashboard_table_row.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Security Dashboard Table Row', () => {
  let vm;
  let props;
  const Component = Vue.extend(component);

  beforeEach(() => {
    const getters = { loadingVulnerabilities: () => false };
    const store = new Vuex.Store({ getters });
    const vulnerability = {
      severity: 'high',
      description: 'Test vulnerability',
      confidence: 'medium',
      project: { name_with_namespace: 'project name' },
    };

    props = { vulnerability };
    vm = mountComponentWithStore(Component, { store, props });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('rendered output', () => {
    it('should render the severity', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[0].textContent)
        .toContain(props.vulnerability.severity);
    });

    it('should render the description', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[1].textContent)
        .toContain(props.vulnerability.description);
    });

    it('should render the project namespace', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[1].textContent)
        .toContain(props.vulnerability.project.name_with_namespace);
    });

    it('should render the confidence', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[2].textContent)
        .toContain(props.vulnerability.confidence);
    });
  });
});
