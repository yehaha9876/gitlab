import Vue from 'vue';
import store from 'ee/ide/stores';
import unstageButton from 'ee/ide/components/commit_sidebar/unstage_button.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { file, resetStore } from '../../helpers';

describe('IDE unstage file button', () => {
  let vm;
  let f;

  beforeEach(() => {
    const Component = Vue.extend(unstageButton);
    f = file();

    vm = createComponentWithStore(Component, store, {
      file: f,
    });

    spyOn(vm, 'unstageChange');

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders button to unstage', () => {
    expect(vm.$el.querySelectorAll('.btn').length).toBe(1);
  });

  it('calls store with unnstage button', () => {
    vm.$el.querySelector('.btn').click();

    expect(vm.unstageChange).toHaveBeenCalledWith(f);
  });
});
