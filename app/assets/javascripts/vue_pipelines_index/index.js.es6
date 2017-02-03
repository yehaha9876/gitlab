/* eslint-disable no-param-reassign */
/* global Vue, VueResource, gl */
<<<<<<< HEAD

window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
require('../vue_shared/components/commit');
require('../vue_pagination/index');
require('../vue_shared/vue_resource_interceptor');
require('./status');
require('./store');
require('./pipeline_url');
require('./stage');
require('./stages');
require('./pipeline_actions');
require('./time_ago');
require('./pipelines');

$(() => new Vue({
  el: document.querySelector('.vue-pipelines-index'),

  data() {
    const project = document.querySelector('.pipelines');
    const svgs = document.querySelector('.pipeline-svgs').dataset;

    // Transform svgs DOMStringMap to a plain Object.
    const svgsObject = Object.keys(svgs).reduce((acc, element) => {
      acc[element] = svgs[element];
      return acc;
    }, {});

    return {
      scope: project.dataset.url,
      store: new gl.PipelineStore(),
      svgs: svgsObject,
    };
  },
  components: {
    'vue-pipelines': gl.VuePipelines,
  },
  template: `
    <vue-pipelines
      :scope='scope'
      :store='store'
      :svgs='svgs'
    >
    </vue-pipelines>
  `,
}));
=======

//= require vue
/*= require vue-resource
/*= require vue_shared/vue_resource_interceptor */
/*= require ./pipelines.js.es6 */

$(() => {
  Vue.use(VueResource);

  return new Vue({
    el: document.querySelector('.vue-pipelines-index'),

    data() {
      const project = document.querySelector('.pipelines');
      const svgs = document.querySelector('.pipeline-svgs').dataset;

      // Transform svgs DOMStringMap to a plain Object.
      const svgsObject = Object.keys(svgs).reduce((acc, element) => {
        acc[element] = svgs[element];
        return acc;
      }, {});

      return {
        scope: project.dataset.url,
        store: new gl.PipelineStore(),
        svgs: svgsObject,
      };
    },
    components: {
      'vue-pipelines': gl.VuePipelines,
    },
    template: `
      <vue-pipelines
        :scope='scope'
        :store='store'
        :svgs='svgs'
      >
      </vue-pipelines>
    `,
  });
});
>>>>>>> fdbdd45... Merge branch 'master' into fe-commit-mr-pipelines
