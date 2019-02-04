import Vue from 'vue';
import { mapState } from 'vuex';
import environmentsComponent from 'ee_else_ce/environments/components/environments_app.vue';
import Translate from '../vue_shared/translate';
import store from './stores/index';

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
        },
      });
    },
  });
