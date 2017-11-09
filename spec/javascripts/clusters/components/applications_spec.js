import Vue from 'vue';
import applications from '~/clusters/components/applications.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Applications', () => {
  let vm;
  let Applications;

  beforeEach(() => {
    Applications = Vue.extend(applications);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('', () => {
    beforeEach(() => {
      vm = mountComponent(Applications, {
        applications: {
          helm: { title: 'Helm Tiller' },
          ingress: { title: 'Ingress' },
          runner: { title: 'GitLab Runner' },
        },
      });
    });

    it('renders a row for Helm Tiller', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-helm')).toBeDefined();
    });

    it('renders a row for Ingress', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-ingress')).toBeDefined();
    });

    /* * /
    it('renders a row for GitLab Runner', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-runner')).toBeDefined();
    });
    /* */
  });
});
