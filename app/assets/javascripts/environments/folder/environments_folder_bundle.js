import Vue from 'vue';
import environmentsFolderApp from './environments_folder_view.vue';
import { parseBoolean } from '../../lib/utils/common_utils';
import Translate from '../../vue_shared/translate';

Vue.use(Translate);

export default () =>
  new Vue({
    el: '#environments-folder-list-view',
    components: {
      environmentsFolderApp,
    },
    data() {
      const environmentsData = document.querySelector(this.$options.el).dataset;

      return {
        endpoint: environmentsData.endpoint,
        folderName: environmentsData.folderName,
        cssContainerClass: environmentsData.cssClass,
        canCreateDeployment: parseBoolean(environmentsData.canCreateDeployment),
        canReadEnvironment: parseBoolean(environmentsData.canReadEnvironment),
        canaryDeploymentFeatureId: environmentsData.canaryDeploymentFeatureId,
        showCanaryDeploymentCallout: parseBoolean(environmentsData.showCanaryDeploymentCallout),
        userCalloutsPath: environmentsData.userCalloutsPath,
        lockPromotionSvgPath: environmentsData.lockPromotionSvgPath,
        helpCanaryDeploymentsPath: environmentsData.helpCanaryDeploymentsPath,
      };
    },
    render(createElement) {
      return createElement('environments-folder-app', {
        props: {
          endpoint: this.endpoint,
          folderName: this.folderName,
          cssContainerClass: this.cssContainerClass,
          canCreateDeployment: this.canCreateDeployment,
          canReadEnvironment: this.canReadEnvironment,
          canaryDeploymentFeatureId: this.canaryDeploymentFeatureId,
          showCanaryDeploymentCallout: this.showCanaryDeploymentCallout,
          userCalloutsPath: this.userCalloutsPath,
          lockPromotionSvgPath: this.lockPromotionSvgPath,
          helpCanaryDeploymentsPath: this.helpCanaryDeploymentsPath,
        },
      });
    },
  });
