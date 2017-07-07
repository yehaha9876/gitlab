import { storiesOf } from '@storybook/vue';
import { addonKnobs, boolean, select, text } from '@storybook/addon-knobs';
import camelize from 'camelize';
import Vue from 'vue';
import mrWidgetOptions from '../app/assets/javascripts/vue_merge_request_widget/mr_widget_options';
import * as mrWidget from '../app/assets/javascripts/vue_merge_request_widget/dependencies';
import mockData from '../spec/javascripts/vue_mr_widget/mock_data';
import { prometheusMockData } from '../spec/javascripts/prometheus_metrics/mock_data';

// gl global stuff that isn't imported
import '../app/assets/javascripts/lib/utils/datetime_utility';
import '../app/assets/javascripts/lib/utils/common_utils';
import '../app/assets/javascripts/commons/bootstrap';
import '../app/assets/javascripts/flash';

window.gon = window.gon || {};
window.gon.current_user_id = 1;

const stories = storiesOf('MR Widget States', module);

function makeStory(options) {
  return addonKnobs()(() => ({
    components: mrWidget,
    data() {
      return {
        service: {},
      };
    },
    computed: {
      componentName() {
        return mrWidget.stateMaps.stateToComponentMap[this.mr.state];
      },
      mr() {
        return {
          ...options,
          state: this.state,
          branch_missing: boolean('Branch missing', false),
        };
      },
    },
    template: `
      <div class="container-fluid container-limited limit-container-width">
        <div class="content" id="content-body">
          <div class="mr-state-widget prepend-top-default">
            <locked-state
              :mr="mr"
              :service="service" />
          </div>
        </div>
      </div>
    `,
  }));
}

stories.add('Locked', makeStory({
  state: 'locked',
  targetBranchPath: '/branch-path',
  targetBranch: 'branch',
}));

export default stories;
