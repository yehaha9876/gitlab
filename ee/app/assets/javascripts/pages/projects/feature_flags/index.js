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
          endpoint: document.querySelector(this.$options.el).dataset.endpoint,
          errorStateSvgPath: document.querySelector(this.$options.el).dataset.errorStateSvgPath,
          featureFlagsHelpPagePath: document.querySelector(this.$options.el).dataset
            .featureFlagsHelpPagePath,
        };
      },
      render(createElement) {
        return createElement('feature-flags-component', {
          props: {
            endpoint: this.endpoint,
            errorStateSvgPath: this.errorStateSvgPath,
            featureFlagsHelpPagePath: this.featureFlagsHelpPagePath,
            csrfToken: csrf.token,
          },
        });
      },
    }),
);
