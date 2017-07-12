import Vue from 'vue';
import { storiesOf } from '@storybook/vue';
// import { makeComponent } from '../../spec/javascripts/vue_mr_widget/components/mr_widget_code_quality_spec';
import mrWidgetCodeQuality from '../../app/assets/javascripts/vue_merge_request_widget/ee/components/mr_widget_code_quality.vue';
import Store from '../../app/assets/javascripts/vue_merge_request_widget/ee/stores/mr_widget_store';
import Service from '../../app/assets/javascripts/vue_merge_request_widget/ee/services/mr_widget_service';

const codeQualityStories = storiesOf('MR Widget EE.Code quality', module);

import mockData, { baseIssues, headIssues } from '../../spec/javascripts/vue_mr_widget/mock_data';

const noop = () => {};

const interceptor = (request, next) => {
  if (request.url === 'head.json') {
    next(request.respondWith(JSON.stringify(headIssues), {
      status: 200,
    }));
  }

  if (request.url === 'base.json') {
    next(request.respondWith(JSON.stringify(baseIssues), {
      status: 200,
    }));
  }
};

function codeQuality() {
  const MRWidgetCodeQuality = Vue.extend(mrWidgetCodeQuality);
  const mr = new Store(mockData);
  const service = new Service('');
  const props = {
    mr,
    service,
  };
  return new MRWidgetCodeQuality({ propsData: props }).$mount();
}

function makeStory({
  beforeFetch = () => {},
  afterFetch = () => {},
} = {}) {
  return () => ({
    components: {
      mrWidgetCodeQuality,
    },
    data() {
      return {
        mr: new Store(mockData),
        service: new Service(''),
      };
    },
    created() {
      Vue.http.interceptors = Vue.http.interceptors.filter(i => i !== interceptor && i !== noop);
      Vue.http.interceptors.push(interceptor);
      beforeFetch(this.mr);
      setTimeout(() => afterFetch(this.mr), 0);
    },
    template: `
      <div class="container-fluid container-limited limit-container-width">
        <div class="content" id="content-body">
          <div class="mr-state-widget prepend-top-default">
            <mr-widget-code-quality :mr="mr" :service="service" />
          </div>
        </div>
      </div>
    `,
  });
}

codeQualityStories.add('Improved', makeStory({
  afterFetch: (mr) => {
    mr.codeclimateMetrics.newIssues = [];
  },
}));

codeQualityStories.add('Degraded', makeStory());

codeQualityStories.add('Loading', makeStory({
  beforeFetch: () => {
    Vue.http.interceptors = Vue.http.interceptors.filter(i => i !== interceptor);
    Vue.http.interceptors.push(noop);
  },
}));

codeQualityStories.add('Error', makeStory({
  beforeFetch: () => {
    Vue.http.interceptors = Vue.http.interceptors.filter(i => i !== interceptor);
  },
}));
