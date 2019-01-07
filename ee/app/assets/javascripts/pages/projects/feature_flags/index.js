import Vue from 'vue';
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
      created() {
        const data = document.querySelector(this.$options.el).dataset;
        this.endpoint = data.endpoint;
        this.errorStateSvgPath = data.errorStateSvgPath;
      },
      render(createElement) {
        return createElement('feature-flags-component', {
          props: {
            endpoint: this.endpoint,
            errorStateSvgPath: this.errorStateSvgPath,
            csrfToken: csrf.token,
          },
        });
      },
    }),
);
