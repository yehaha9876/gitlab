import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetChecking',
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon status="success" />
      <div class="media-body">
        <span class="bold">
          Checking ability to merge automatically
          <i
            class="fa fa-spinner fa-spin"
            aria-hidden="true" />
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
