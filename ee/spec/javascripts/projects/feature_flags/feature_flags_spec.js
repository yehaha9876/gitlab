import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import featureFlagsComponent from 'ee/feature_flags/components/feature_flags.vue';
import Store from 'ee/feature_flags/store/feature_flags_store';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import {
  featureFlag
} from './mock_data';

describe('Feature Flags', () => {
  const mockData = {
    endpoint: 'feature_flags.json',
    store: new Store(),
    csrfToken: 'testToken',
    errorStateSvgPath: '/assets/illustrations/feature_flag.svg',
  };

  let FeatureFlagsComponent;
  let component;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    FeatureFlagsComponent = Vue.extend(featureFlagsComponent);
  });

  afterEach(() => {
    component.$destroy();
    mock.restore();
  });

  describe('successful request', () => {
    describe('with paginated feature flags', () => {
      beforeEach(done => {
        mock.onGet(mockData.endpoint).reply(
          200, {
            feature_flags: [featureFlag],
            count: {
              all: 37,
              enabled: 5,
              disabled: 32,
            },
          }, {
            'X-nExt-pAge': '2',
            'x-page': '1',
            'X-Per-Page': '1',
            'X-Prev-Page': '',
            'X-TOTAL': '37',
            'X-Total-Pages': '2',
          },
        );

        component = mountComponent(FeatureFlagsComponent, mockData);

        setTimeout(() => {
          done();
        }, 0);
      });

      it('should render a table with feature flags', () => {
        expect(component.$el.querySelectorAll('table-holder')).not.toBeNull();
        expect(component.$el.querySelector('.feature-flag-name').textContent.trim()).toEqual(
          featureFlag.name,
        );

        expect(component.$el.querySelector('.feature-flag-description').textContent.trim()).toEqual(
          featureFlag.description,
        );
      });

      describe('pagination', () => {
        it('should render pagination', () => {
          expect(component.$el.querySelectorAll('.gl-pagination li').length).toEqual(5);
        });

        it('should make an API request when page is clicked', done => {
          spyOn(component, 'updateContent');
          setTimeout(() => {
            component.$el.querySelector('.gl-pagination li:nth-child(5) a').click();

            expect(component.updateContent).toHaveBeenCalledWith({
              scope: 'all',
              page: '2'
            });
            done();
          }, 0);
        });

        it('should make an API request when using tabs', done => {
          setTimeout(() => {
            spyOn(component, 'updateContent');
            component.$el.querySelector('.js-featureflags-tab-enabled').click();

            expect(component.updateContent).toHaveBeenCalledWith({
              scope: 'enabled',
              page: '1'
            });
            done();
          }, 0);
        });
      });
    });
  });

  describe('unsuccessful request', () => {
    beforeEach(done => {
      mock.onGet(mockData.endpoint).reply(500, {});

      component = mountComponent(FeatureFlagsComponent, mockData);

      setTimeout(() => {
        done();
      }, 0);
    });

    it('should render error state', () => {
      expect(component.$el.querySelector('.empty-state').textContent.trim()).toContain(
        'There was an error fetching the feature flags. Try again in a few moments or contact your support team.',
      );
    })
  });
})