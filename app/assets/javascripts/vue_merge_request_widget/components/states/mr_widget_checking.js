
import ciIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  name: 'MRWidgetChecking',
  components: {
    ciIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <ci-icon :status="{ group: 'success', icon: 'icon_status_success' }" />
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
