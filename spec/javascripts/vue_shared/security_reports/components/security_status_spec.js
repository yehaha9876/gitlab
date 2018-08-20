import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/security_status.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { ICON_SUCCESS, ICON_WARNING } from '~/reports/constants';

describe('security status', () => {
  const Component = Vue.extend(component);
  const commitShortSha = 'g1tl4bru135';
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  beforeEach(() => {
    vm = mountComponent(Component, { commitShortSha });
  });

  describe('before report has loaded', () => {
    it('has the `isLoading` flag', () => {
      expect(vm.isLoading).toBeTruthy();
    });

    it('sets the status to loading', () => {
      expect(vm.status).toEqual('loading');
    });

    it('does not have any reports', () => {
      expect(vm.hasReports).toBeFalsy();
    });
  });

  describe('when the latest commit has no reports', () => {
    beforeEach(() => {
      // TODO: Send down a no report response
    });

    it('does not have the `isLoading` flag', () => {
      expect(vm.isLoading).toBeFalsy();
    });

    it('does not have any reports', () => {
      expect(vm.hasReports).toBeFalsy();
    });
  });

  describe('when `is_secure = true`', () => {
    beforeEach(() => {
      // TODO: Send down a succesful report response
    });

    it('sets the status to success', () => {
      expect(vm.status).toEqual(ICON_SUCCESS);
    });

    it('has reports', () => {
      expect(vm.hasReports).toBeTruthy();
    });

    // TODO: Hook this up properly
    it('links to the reports', () => {});
  });

  describe('when `is_secure = false`', () => {
    beforeEach(() => {
      // TODO: Send down a failed report response
    });

    it('sets the status to warning', () => {
      expect(vm.status).toEqual(ICON_WARNING);
    });

    it('has reports', () => {
      expect(vm.hasReports).toBeTruthy();
    });

    // TODO: Hook this up properly
    it('links to the reports', () => {});
  });
});
