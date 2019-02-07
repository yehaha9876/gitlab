import Vue from 'vue';
import { mapState } from 'vuex';
import environmentsComponent from './components/environments_app.vue';
import Translate from '../vue_shared/translate';
import store from './stores';

// ee-only start
import CanaryCalloutMixin from 'ee/environments/mixins/canary_callout_mixin'; // eslint-disable-line import/order
// ee-only end

Vue.use(Translate);

export default () =>
  new Vue({
    el: '#environments-list-view',
    store() {
      return store(document.querySelector(this.el).dataset);
    },
    components: {
      environmentsComponent,
    },
    // ee-only start
    mixins: [CanaryCalloutMixin],
    // ee-only end
    computed: {
      ...mapState([
        'endpoint',
        'newEnvironmentPath',
        'helpPagePath',
        'cssContainerClass',
        'canCreateEnvironment',
        'canCreateDeployment',
        'canReadEnvironment',
      ]),
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
