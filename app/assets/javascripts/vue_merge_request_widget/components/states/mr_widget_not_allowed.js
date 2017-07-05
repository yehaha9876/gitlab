import ciIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  name: 'MRWidgetNotAllowed',
  components: {
    ciIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <ci-icon :status="{ group: 'success', icon: 'icon_status_success' }" />
      <div class="media-body">
        <button
          type="button"
          class="btn btn-success btn-small"
          disabled="true">
          Merge
        </button>
        <span class="bold">
          Ready to be merged automatically.
          Ask someone with write access to this repository to merge this request.
        </span>
      </div>
    </div>
  `,
};
