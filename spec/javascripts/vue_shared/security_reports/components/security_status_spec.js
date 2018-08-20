import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import component from 'ee/vue_shared/security_reports/components/security_status.vue';
import { ICON_SUCCESS, ICON_WARNING } from '~/reports/constants';

describe('security status', () => {
  const Component = Vue.extend(component);
  const commitShortSha = 'g1tl4bru135';
  const pipelineUrl = 'http://gitlab.com/';

  let vm;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  describe('before report has loaded', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { commitShortSha });
    });

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
      vm = mountComponent(Component, { commitShortSha });
      mock
        .onGet(`/notarealendpoint/${commitShortSha}`)
        .reply(204);
    });

    it('does not have the `isLoading` flag', done => {
      setTimeout(() => {
        expect(vm.isLoading).toBeFalsy();
        done();
      }, 0);
    });

    it('does not have any reports', done => {
      setTimeout(() => {
        expect(vm.hasReports).toBeFalsy();
        done();
      }, 0);
    });
  });

  describe('when `is_secure = true`', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { commitShortSha });
      mock
        .onGet(`/notarealendpoint/${commitShortSha}`)
        .reply(200, {
          is_secure: true,
          pipeline_url: pipelineUrl,
        });
    });

    it('sets the status to success', done => {
      setTimeout(() => {
        expect(vm.status).toEqual(ICON_SUCCESS);
        done();
      }, 0);
    });

    it('has reports', done => {
      setTimeout(() => {
        expect(vm.hasReports).toBeTruthy();
        done();
      }, 0);
    });

    // TODO: Hook this up properly
    it('links to the reports', () => { });
  });

  describe('when `is_secure = false`', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { commitShortSha });
      mock
        .onGet(`/notarealendpoint/${commitShortSha}`)
        .reply(200, {
          is_secure: false,
          pipeline_url: pipelineUrl,
        });
    });

    it('sets the status to warning', done => {
      setTimeout(() => {
        expect(vm.status).toEqual(ICON_WARNING);
        done();
      }, 0);
    });

    it('has reports', done => {
      setTimeout(() => {
        expect(vm.hasReports).toBeTruthy();
        done();
      }, 0);
    });

    // TODO: Hook this up properly
    it('links to the reports', () => { });
  });
});
