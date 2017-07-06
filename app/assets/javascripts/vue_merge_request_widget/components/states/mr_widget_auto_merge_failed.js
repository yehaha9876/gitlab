import eventHub from '../../event_hub';
import ciIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  name: 'MRWidgetAutoMergeFailed',
  props: {
    mr: { type: Object, required: true },
  },
  data() {
    return {
      isRefreshing: false,
    };
  },
  components: {
    ciIcon,
  },
  methods: {
    refreshWidget() {
      this.isRefreshing = true;
      eventHub.$emit('MRWidgetUpdateRequested', () => {
        this.isRefreshing = false;
      });
    },
  },
  template: `
    <div class="mr-widget-body media">
      <ci-icon :status="{ group: 'failed', icon: 'icon_status_failed' }" />
      <div class="media-body">
        <span class="merge-error-text bold">
          {{mr.mergeError}}.
        </span>
        <span class="bold">
          This merge request failed to be merged automatically
        </span>
        <button
          @click="refreshWidget"
          :disabled="isRefreshing"
          type="button"
          class="btn btn-xs btn-default">
          <i
            v-if="isRefreshing"
            class="fa fa-spinner fa-spin"
            aria-hidden="true" />
          Refresh
        </button>
      </div>
    </div>
  `,
};
