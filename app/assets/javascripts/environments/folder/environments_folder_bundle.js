import Vue from 'vue';
import { mapState } from 'vuex';
import environmentsFolderApp from './environments_folder_view.vue';
import Translate from '../../vue_shared/translate';
import store from '../stores';

// ee-only start
import CanaryCalloutMixin from 'ee/environments/mixins/canary_callout_mixin'; // eslint-disable-line import/order
// ee-only end

Vue.use(Translate);

export default () =>
  new Vue({
    el: '#environments-folder-list-view',
    store() {
      return store(document.querySelector(this.el).dataset);
    },
    components: {
      environmentsFolderApp,
    },
    // ee-only start
    mixins: [CanaryCalloutMixin],
    // ee-only end
    computed: {
      ...mapState([
        'endpoint',
        'folderName',
        'cssContainerClass',
        'canCreateDeployment',
        'canReadEnvironment',
      ]),
    },
    render(createElement) {
      return createElement('environments-folder-app', {
        props: {
          endpoint: this.endpoint,
          folderName: this.folderName,
          cssContainerClass: this.cssContainerClass,
          canCreateDeployment: this.canCreateDeployment,
          canReadEnvironment: this.canReadEnvironment,
          // ee-only start
          canaryDeploymentFeatureId: this.canaryDeploymentFeatureId,
          showCanaryDeploymentCallout: this.showCanaryDeploymentCallout,
          userCalloutsPath: this.userCalloutsPath,
          lockPromotionSvgPath: this.lockPromotionSvgPath,
          helpCanaryDeploymentsPath: this.helpCanaryDeploymentsPath,
          // ee-only end
        },
      });
    },
  });
