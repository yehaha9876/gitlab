import Vue from 'vue';
import environmentsComponent from './components/environments_app.vue';
import { parseBoolean } from '../lib/utils/common_utils';
import Translate from '../vue_shared/translate';

Vue.use(Translate);

export default () =>
  new Vue({
    el: '#environments-list-view',
    components: {
      environmentsComponent,
    },
    data() {
      const environmentsData = document.querySelector(this.$options.el).dataset;

      return {
        endpoint: environmentsData.environmentsDataEndpoint,
        newEnvironmentPath: environmentsData.newEnvironmentPath,
        helpPagePath: environmentsData.helpPagePath,
        cssContainerClass: environmentsData.cssClass,
        canCreateEnvironment: parseBoolean(environmentsData.canCreateEnvironment),
        canCreateDeployment: parseBoolean(environmentsData.canCreateDeployment),
        canReadEnvironment: parseBoolean(environmentsData.canReadEnvironment),
        canaryDeploymentFeatureId: environmentsData.canaryDeploymentFeatureId,
        showCanaryDeploymentCallout: convertPermissionToBoolean(environmentsData.showCanaryDeploymentCallout),
        userCalloutsPath: environmentsData.userCalloutsPath,
      };
    },
    render(createElement) {
      return createElement('environments-component', {
        props: {
          endpoint: this.endpoint,
          newEnvironmentPath: this.newEnvironmentPath,
          helpPagePath: this.helpPagePath,
          cssContainerClass: this.cssContainerClass,
          canCreateEnvironment: this.canCreateEnvironment,
          canCreateDeployment: this.canCreateDeployment,
          canReadEnvironment: this.canReadEnvironment,
          canaryDeploymentFeatureId: this.canaryDeploymentFeatureId,
          showCanaryDeploymentCallout: this.showCanaryDeploymentCallout,
          userCalloutsPath: this.userCalloutsPath,
        },
      });
    },
  });
