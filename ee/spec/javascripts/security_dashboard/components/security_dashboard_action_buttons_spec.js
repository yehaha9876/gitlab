import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import component from 'ee/security_dashboard/components/security_dashboard_action_buttons.vue';
import createStore from 'ee/security_dashboard/store';

describe('Security Dashboard Action Buttons', () => {
  let vm;
  let props;
  const Component = Vue.extend(component);
  const store = createStore();

  beforeEach(() => {
    props = { vulnerability: { id: 123 } };

    vm = mountComponentWithStore(Component, { props, store });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render one button', () => {
    expect(vm.$el.querySelectorAll('.btn')).toHaveLength(1);
  });

  describe('More Info Button', () => {
    it('should render the More info button', () => {
      expect(vm.$el.querySelector('.js-more-info')).not.toBeNull();
    });
  });
});
