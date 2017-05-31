import Vue from 'vue';
import Visibility from 'visibilityjs';
import Poll from '../lib/utils/poll';
import pipelineGraph from './components/graph/graph_component.vue';
import PipelineService from './services/pipeline_service';
import PipelineStore from './stores/pipeline_store';

document.addEventListener('DOMContentLoaded', () => {
  const DOMdata = document.getElementById('js-pipeline-graph-vue').dataset;
  const store = new PipelineStore();
  const service = new PipelineService(DOMdata.endpoint);

  new Vue({
    el: '#js-pipeline-graph-vue',
    components: {
      pipelineGraph,
    },
    data() {
      return {
        state: store.state,
      };
    },
    created() {
      const poll = new Poll({
        resource: service,
        method: 'getPipeline',
        successCallback: (response) => {
          store.storeGraph(response.json().details.stages)
        },
        errorCallback: () => new Flash('An error occurred while fetching the pipeline.'),
      });

      if (!Visibility.hidden()) {
        poll.makeRequest();
      }

      Visibility.change(() => {
        if (!Visibility.hidden()) {
          poll.restart();
        } else {
          poll.stop();
        }
      });
    },
    template: `
      <pipeline-graph :state="state"></pipeline-graph>
    `,
  });
});

