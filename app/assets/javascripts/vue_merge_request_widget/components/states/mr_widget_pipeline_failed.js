import ciIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  name: 'MRWidgetPipelineBlocked',
  components: {
    ciIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <ci-icon :status="{ group: 'failed', icon: 'icon_status_failed' }" />
      <div class="media-body">
        <span class="bold">
          The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure
        </span>
        <button
          class="btn btn-success btn-xs"
          disabled="true"
          type="button">
          Merge
        </button>
      </div>
    </div>
  `,
};
