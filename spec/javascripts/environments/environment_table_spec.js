import Vue from 'vue';
import environmentTableComp from '~/environments/components/environments_table.vue';
import eventHub from '~/environments/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { deployBoardMockData } from './mock_data';

describe('Environment table', () => {
  let Component;
  let vm;

  beforeEach(() => {
    Component = Vue.extend(environmentTableComp);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('Should render a table', () => {
    const mockItem = {
      name: 'review',
      folderName: 'review',
      size: 3,
      isFolder: true,
      environment_path: 'url',
    };

    vm = mountComponent(Component, {
      environments: [mockItem],
      canReadEnvironment: true,
      // ee-only start
      canaryDeploymentFeatureId: 'canary_deployment',
      showCanaryDeploymentCallout: true,
      userCalloutsPath: '/callouts',
      lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
      helpCanaryDeploymentsPath: 'help/canary-deployments',
      // ee-only end
    });

    expect(vm.$el.getAttribute('class')).toContain('ci-table');
  });

  it('should render deploy board container when data is provided', () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
      hasDeployBoard: true,
      deployBoardData: deployBoardMockData,
      isDeployBoardVisible: true,
      isLoadingDeployBoard: false,
      isEmptyDeployBoard: false,
    };

    vm = mountComponent(Component, {
      environments: [mockItem],
      canCreateDeployment: false,
      canReadEnvironment: true,
      // ee-only start
      canaryDeploymentFeatureId: 'canary_deployment',
      showCanaryDeploymentCallout: true,
      userCalloutsPath: '/callouts',
      lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
      helpCanaryDeploymentsPath: 'help/canary-deployments',
      // ee-only end
    });

    expect(vm.$el.querySelector('.js-deploy-board-row')).toBeDefined();
    expect(vm.$el.querySelector('.deploy-board-icon')).not.toBeNull();
  });

  it('should toggle deploy board visibility when arrow is clicked', done => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
      hasDeployBoard: true,
      deployBoardData: {
        instances: [{ status: 'ready', tooltip: 'foo' }],
        abort_url: 'url',
        rollback_url: 'url',
        completion: 100,
        is_completed: true,
      },
      isDeployBoardVisible: false,
    };

    eventHub.$on('toggleDeployBoard', env => {
      expect(env.id).toEqual(mockItem.id);
      done();
    });

    vm = mountComponent(Component, {
      environments: [mockItem],
      canReadEnvironment: true,
      // ee-only start
      canaryDeploymentFeatureId: 'canary_deployment',
      showCanaryDeploymentCallout: true,
      userCalloutsPath: '/callouts',
      lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
      helpCanaryDeploymentsPath: 'help/canary-deployments',
      // ee-only end
    });

    vm.$el.querySelector('.deploy-board-icon').click();
  });

  describe('sortEnvironments', () => {
    it('should sort environments by last updated', () => {
      const mockItems = [
        {
          name: 'old',
          size: 3,
          isFolder: false,
          last_deployment: {
            created_at: new Date(2019, 0, 5).toISOString(),
          },
        },
        {
          name: 'new',
          size: 3,
          isFolder: false,
          last_deployment: {
            created_at: new Date(2019, 1, 5).toISOString(),
          },
        },
        {
          name: 'older',
          size: 3,
          isFolder: false,
          last_deployment: {
            created_at: new Date(2018, 0, 5).toISOString(),
          },
        },
        {
          name: 'an environment with no deployment',
        },
      ];

      vm = mountComponent(Component, {
        environments: mockItems,
        canReadEnvironment: true,
        // ee-only start
        canaryDeploymentFeatureId: 'canary_deployment',
        showCanaryDeploymentCallout: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
        // ee-only end
      });

      const [old, newer, older, noDeploy] = mockItems;

      expect(vm.sortEnvironments(mockItems)).toEqual([newer, old, older, noDeploy]);
    });

    it('should push environments with no deployments to the bottom', () => {
      const mockItems = [
        {
          name: 'production',
          size: 1,
          id: 2,
          state: 'available',
          external_url: 'https://google.com/production',
          environment_type: null,
          last_deployment: null,
          has_stop_action: false,
          environment_path: '/Commit451/lab-coat/environments/2',
          stop_path: '/Commit451/lab-coat/environments/2/stop',
          folder_path: '/Commit451/lab-coat/environments/folders/production',
          created_at: '2019-01-17T16:26:10.064Z',
          updated_at: '2019-01-17T16:27:37.717Z',
          can_stop: true,
        },
        {
          name: 'review/225addcibuildstatus',
          size: 2,
          isFolder: true,
          isLoadingFolderContent: false,
          folderName: 'review',
          isOpen: false,
          children: [],
          id: 12,
          state: 'available',
          external_url: 'https://google.com/review/225addcibuildstatus',
          environment_type: 'review',
          last_deployment: null,
          has_stop_action: false,
          environment_path: '/Commit451/lab-coat/environments/12',
          stop_path: '/Commit451/lab-coat/environments/12/stop',
          folder_path: '/Commit451/lab-coat/environments/folders/review',
          created_at: '2019-01-17T16:27:37.877Z',
          updated_at: '2019-01-17T16:27:37.883Z',
          can_stop: true,
        },
        {
          name: 'staging',
          size: 1,
          id: 1,
          state: 'available',
          external_url: 'https://google.com/staging',
          environment_type: null,
          last_deployment: {
            created_at: '2019-01-17T16:26:15.125Z',
            scheduled_actions: [],
          },
        },
      ];

      vm = mountComponent(Component, {
        environments: mockItems,
        canReadEnvironment: true,
        // ee-only start
        canaryDeploymentFeatureId: 'canary_deployment',
        showCanaryDeploymentCallout: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
        // ee-only end
      });

      const [prod, review, staging] = mockItems;

      expect(vm.sortEnvironments(mockItems)).toEqual([review, staging, prod]);
    });

    it('should sort environments by folder first', () => {
      const mockItems = [
        {
          name: 'old',
          size: 3,
          isFolder: false,
          last_deployment: {
            created_at: new Date(2019, 0, 5).toISOString(),
          },
        },
        {
          name: 'new',
          size: 3,
          isFolder: false,
          last_deployment: {
            created_at: new Date(2019, 1, 5).toISOString(),
          },
        },
        {
          name: 'older',
          size: 3,
          isFolder: true,
          children: [],
        },
      ];

      vm = mountComponent(Component, {
        environments: mockItems,
        canReadEnvironment: true,
        // ee-only start
        canaryDeploymentFeatureId: 'canary_deployment',
        showCanaryDeploymentCallout: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
        // ee-only end
      });

      const [old, newer, older] = mockItems;

      expect(vm.sortEnvironments(mockItems)).toEqual([older, newer, old]);
    });

    it('should break ties by name', () => {
      const mockItems = [
        {
          name: 'old',
          isFolder: false,
        },
        {
          name: 'new',
          isFolder: false,
        },
        {
          folderName: 'older',
          isFolder: true,
        },
      ];

      vm = mountComponent(Component, {
        environments: mockItems,
        canReadEnvironment: true,
        // ee-only start
        canaryDeploymentFeatureId: 'canary_deployment',
        showCanaryDeploymentCallout: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
        // ee-only end
      });

      const [old, newer, older] = mockItems;

      expect(vm.sortEnvironments(mockItems)).toEqual([older, newer, old]);
    });
  });

  describe('sortedEnvironments', () => {
    it('it should sort children as well', () => {
      const mockItems = [
        {
          name: 'production',
          last_deployment: null,
        },
        {
          name: 'review/225addcibuildstatus',
          isFolder: true,
          folderName: 'review',
          isOpen: true,
          children: [
            {
              name: 'review/225addcibuildstatus',
              last_deployment: {
                created_at: '2019-01-17T16:26:15.125Z',
              },
            },
            {
              name: 'review/master',
              last_deployment: {
                created_at: '2019-02-17T16:26:15.125Z',
              },
            },
          ],
        },
        {
          name: 'staging',
          last_deployment: {
            created_at: '2019-01-17T16:26:15.125Z',
          },
        },
      ];
      const [production, review, staging] = mockItems;
      const [addcibuildstatus, master] = mockItems[1].children;

      vm = mountComponent(Component, {
        environments: mockItems,
        canReadEnvironment: true,
        // ee-only start
        canaryDeploymentFeatureId: 'canary_deployment',
        showCanaryDeploymentCallout: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
        // ee-only end
      });

      expect(vm.sortedEnvironments.map(env => env.name)).toEqual([
        review.name,
        staging.name,
        production.name,
      ]);

      expect(vm.sortedEnvironments[0].children).toEqual([master, addcibuildstatus]);
    });
  });
  // ee-only start
  describe('ee only', () => {
    it('should render canary callout', () => {
      const mockItem = {
        name: 'review',
        folderName: 'review',
        size: 3,
        isFolder: true,
        environment_path: 'url',
        showCanaryCallout: true,
      };

      vm = mountComponent(Component, {
        environments: [mockItem],
        canCreateDeployment: false,
        canReadEnvironment: true,
        canaryDeploymentFeatureId: 'canary_deployment',
        showCanaryDeploymentCallout: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
      });

      expect(vm.$el.querySelector('.canary-deployment-callout')).not.toBeNull();
    });
  });
  // ee-only end
});
