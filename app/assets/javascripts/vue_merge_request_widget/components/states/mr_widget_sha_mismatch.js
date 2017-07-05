import ciIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  name: 'MRWidgetSHAMismatch',
  components: {
    ciIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <ci-icon :status="{ group: 'failed', icon: 'icon_status_failed' }" />
      <div class="media-body">
        <span class="bold">
          The source branch HEAD has recently changed. Please reload the page and review the changes before merging.
        </span>
        <button
          type="button"
          class="btn btn-success btn-xs"
          disabled="true">
          Merge
        </button>
      </div>
    </div>
  `,
};
