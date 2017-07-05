import ciIcon from '../../../vue_shared/components/ci_icon.vue';
import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetFailedToMerge',
  props: {
    mr: { type: Object, required: true },
  },
  data() {
    return {
      timer: 10,
      isRefreshing: false,
    };
  },
  mounted() {
    setInterval(() => {
      this.updateTimer();
    }, 1000);
  },
  created() {
    eventHub.$emit('DisablePolling');
  },
  computed: {
    timerText() {
      return this.timer > 1 ? `${this.timer} seconds` : 'a second';
    },
  },
  methods: {
    refresh() {
      this.isRefreshing = true;
      eventHub.$emit('MRWidgetUpdateRequested');
      eventHub.$emit('EnablePolling');
    },
    updateTimer() {
      this.timer = this.timer - 1;

      if (this.timer === 0) {
        this.refresh();
      }
    },
  },
  components: {
    ciIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <ci-icon :status="{ group: 'failed', icon: 'icon_status_failed' }" />
      <div class="media-body">
        <span
          v-if="!isRefreshing"
          class="bold danger">
          <span
            class="has-error-message"
            v-if="mr.mergeError">
            {{mr.mergeError}}
          </span>
          <span v-else>Merge failed.</span>
          <span
            :class="{ 'has-custom-error': mr.mergeError }">
            Refreshing in {{timerText}} to show the updated status...
          </span>
          <button
            class="btn btn-success btn-xs"
            disabled="true"
            type="button">
            Merge
          </button>
          <button
            @click="refresh"
            class="btn btn-default btn-xs js-refresh-button"
            type="button">
            Refresh now
          </button>
        </span>
        <span
          v-if="isRefreshing"
          class="bold js-refresh-label">
          Refreshing now...
        </span>
      </div>
    </div>
  `,
};
