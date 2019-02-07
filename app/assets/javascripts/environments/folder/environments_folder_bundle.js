import Vue from 'vue';
import { mapState } from 'vuex';
import environmentsFolderApp from './environments_folder_view.vue';
import Translate from '../../vue_shared/translate';
import store from '../stores/index';

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
        },
      });
    },
  });
