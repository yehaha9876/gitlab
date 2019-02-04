import Vue from 'vue';
import store from './stores/index';
import environmentsComponent from './components/environments_app.vue';
import Translate from '../vue_shared/translate';

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
    render(createElement) {
      return createElement('environments-component');
    },
  });
