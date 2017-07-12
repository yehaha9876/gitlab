import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetChecking',
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <div class="mr-widget-icon">
        <i
          class="fa fa-spinner fa-spin"
          aria-hidden="true" />
      </div>
      <div class="media-body">
        <button
          type="button"
          class="btn btn-success btn-small"
          disabled="true">
          Merge
        </button>
        <span class="spacing bold">
          Checking ability to merge automatically
        </span>
      </div>
    </div>
  `,
};
