import Vue from 'vue';
import store from '~/ide/stores';
import ideContextBar from '~/ide/components/ide_context_bar.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Multi-file editor right context bar', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(ideContextBar);

    vm = createComponentWithStore(Component, store, {
      noChangesStateSvgPath: 'svg',
      committedStateSvgPath: 'svg',
    });

    vm.$store.state.rightPanelCollapsed = false;

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('collapsed', () => {
    beforeEach((done) => {
      vm.$store.state.rightPanelCollapsed = true;

      Vue.nextTick(done);
    });

    it('adds collapsed class', () => {
      expect(vm.$el.classList.contains('is-collapsed')).toBeTruthy();
    });

    it('clicking sidebar collapses the bar', () => {
      spyOn(vm, 'toggleRightPanelCollapsed').and.returnValue(Promise.resolve());

      vm.$el.click();

      expect(vm.toggleRightPanelCollapsed).toHaveBeenCalled();
    });
  });

  it('when expanded clicking the main sidebar is not collapsing the bar', () => {
    spyOn(vm, 'toggleRightPanelCollapsed').and.returnValue(Promise.resolve());

    vm.$el.click();

    expect(vm.toggleRightPanelCollapsed).not.toHaveBeenCalled();
  });
});
