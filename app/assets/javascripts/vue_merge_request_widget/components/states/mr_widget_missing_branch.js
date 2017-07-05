import ciIcon from '../../../vue_shared/components/ci_icon.vue';
import mrWidgetMergeHelp from '../../components/mr_widget_merge_help';

export default {
  name: 'MRWidgetMissingBranch',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'mr-widget-merge-help': mrWidgetMergeHelp,
    ciIcon,
  },
  computed: {
    missingBranchName() {
      return this.mr.sourceBranchRemoved ? 'source' : 'target';
    },
    message() {
      return `If the ${this.missingBranchName} branch exists in your local repository, you can merge this merge request manually using the command line`;
    },
  },
  template: `
    <div class="mr-widget-body media">
      <ci-icon :status="{ group: 'failed', icon: 'icon_status_failed' }" />
      <div class="media-body">
        <span class="bold js-branch-text">
          <span class="capitalize">
            {{missingBranchName}}
          </span> branch does not exist.
          Please restore it or use a different {{missingBranchName}} branch
          <i
            class="fa fa-question-circle has-tooltip"
            :title="message" />
        </span>
        <button
          type="button"
          class="btn btn-success btn-small"
          disabled="true">
          Merge
        </button>
      </div>
    </div>
  `,
};
