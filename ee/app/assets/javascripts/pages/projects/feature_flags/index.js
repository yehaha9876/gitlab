import Vue from 'vue';
import FeatureFlagsComponent from 'ee/feature_flags/components/feature_flags.vue';
import csrf from '~/lib/utils/csrf';

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
          endpoint: '',
          errorStateSvgPath: '',
        };
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
