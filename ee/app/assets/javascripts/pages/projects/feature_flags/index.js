import Vue from 'vue';
import FeatureFlagsStore from '../../../feature_flags/store/feature_flags_store';
import FeatureFlagsComponent from '../../../feature_flags/components/feature_flags.vue';
import Translate from '../../../../../../../app/assets/javascripts/vue_shared/translate';
import csrf from '~/lib/utils/csrf';

Vue.use(Translate);

document.addEventListener(
  'DOMContentLoaded',
  () =>
  new Vue({
    el: '#feature-flags-vue',
    components: {
      FeatureFlagsComponent,
    },
    data() {
      return {
        store: new FeatureFlagsStore(),
      };
    },
    created() {
      this.dataset = document.querySelector(this.$options.el).dataset;
    },
    render(createElement) {
      return createElement('feature-flags-component', {
        props: {
          store: this.store,
          endpoint: this.dataset.endpoint,
          instanceId: this.dataset.instanceId,
          csrfToken: csrf.token,
        },
      });
    },
  }),
);