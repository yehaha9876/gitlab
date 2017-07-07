import { storiesOf } from '@storybook/vue';
import { addonKnobs, boolean, select, number, text } from '@storybook/addon-knobs';
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

const mr = mockData;
mr.isOpen = true;
// copied from mr_widget_deployment_spec
mr.deployments = [
  {
    id: 15,
    name: 'review/diplo',
    url: '/root/acets-review-apps/environments/15',
    stop_url: '/root/acets-review-apps/environments/15/stop',
    metrics_url: '/root/acets-review-apps/environments/15/deployments/1/metrics',
    external_url: 'http://diplo.',
    external_url_formatted: 'diplo.',
    deployed_at: '2017-03-22T22:44:42.258Z',
    deployed_at_formatted: 'Mar 22, 2017 10:44pm',
  },
];
mr.relatedLinks = {
  closing: '<a href="#">#23</a> and <a>#42</a>',
  mentioned: '<a href="#">#7</a>',
};
mr.commitMessage = 'A commit';
mr.mergedAt = 'some time ago';
mr.mergedBy = {
  webUrl: 'http://foo.bar',
  avatarUrl: 'http://gravatar.com/foo',
  name: 'fatihacet',
};
mr.closedAt = mr.mergedAt;
mr.closedBy = mr.mergedBy;
mr.setToMWPSAt = mr.mergedAt;
mr.setToMWPSBy = mr.mergedBy;
mr.removeWIPPath = '/some/path';
mr.mergeError = 'merge error';
mr.pipeline.commit = {
  commit_path: 'something',
  short_id: 'af341ad1',
};
mr.newBlobPath = 'something';
mr.current_user = {
  can_remove_source_branch: true,
  can_revert_on_current_merge_request: null,
  can_cherry_pick_on_current_merge_request: false,
};

window.gon = window.gon || {};
window.gon.current_user_id = 1;

const stories = storiesOf('MR Widget', module);
const mrStates = ['opened', 'locked', 'merged', 'closed', 'reopened'];

function makeStory(options) {
    // relatedLinks: {
    //   closing: window.mrWidgetData.closesIssues ? '<a href="#">#23</a> and <a>#42</a>' : undefined,
    //   mentioned: window.mrWidgetData.mentionsIssues ? '<a href="#">#7</a>' : undefined,
    // },
    // createIssueToResolveDiscussionsPath: text('Create issue', '/create/issue'),
    // isPipelineActive: boolean('Pipeline active', false),
    // shouldRemoveSourceBranch: boolean('shouldRemoveSourceBranch', true),
    // canRemoveSourceBranch: boolean('canRemoveSourceBranch', true),
    // mergeUserId: text('merge user ID', '1'),
    // currentUserId: text('current user ID', '1'),
    // canMerge: boolean('Can merge', false),

  delete mrWidgetOptions.el; // Prevent component mounting

  return addonKnobs()(() => ({
    components: {
      mrWidgetOptions,
    },
    data() {
      return {
        state: select('State', mrStates, 'opened'),
        branchMissing: boolean('Branch missing', false)
      };
    },
    computed: {
      mrData() {
        return {
          ...mr,
          ...options,
          state: this.state,
          project_archived: boolean('Project archived', false),
          branch_missing: boolean('Branch missing', false),
          commit_count: number('Number of commits', 3),
          merge_status: select('Merge status', ['unchecked', 'checked'], 'checked'),
          has_conflicts: boolean('Has conflicts', false),
          work_in_progress: boolean('WIP', false),
          only_allow_merge_if_pipeline_succeeds: boolean('Require MWPS', true),
//   } else if (this.onlyAllowMergeIfPipelineSucceeds && this.isPipelineFailed) {
//   } else if (this.hasMergeableDiscussionsState) {
//   } else if (this.isPipelineBlocked) {
//   } else if (this.hasSHAChanged) {
//   } else if (this.mergeWhenPipelineSucceeds) {
//     return this.mergeError ? 'autoMergeFailed' : 'mergeWhenPipelineSucceeds';
//   } else if (!this.canMerge) {
//   } else if (this.canBeMerged) {
        };
      },
    },
    template: `
      <div class="container-fluid container-limited limit-container-width">
        <div class="content" id="content-body">
          <mr-widget-options :mrData="mrData" />
        </div>
      </div>
    `,
  }));
}

stories.add('All states', makeStory({
  state: 'opened',
  branch_missing: true,
}));
