<script>
import Icon from '~/vue_shared/components/icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { __, sprintf } from '~/locale';

export default {
  components: {
    Icon,
  },
  directives: {
    Tooltip,
  },
  mixins: [timeagoMixin],
  props: {
    finishedTime: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    hasFinishedTime() {
      return this.finishedTime !== null;
    },
    finishedTimeTitle() {
      return sprintf('<span class="bold">%{title}</span><br/><span>%{date}</span>', {
        title: __('Finished'),
        date: this.tooltipTitle(this.finishedTime),
      });
    },
  },
};
</script>
<template>
  <div v-if="hasFinishedTime" class="ops-dashboard-project-time-ago js-dashboard-project-time-ago">
    <icon name="clock" class="ops-dashboard-project-time-ago-icon" />

    <time
      v-tooltip
      :title="finishedTimeTitle"
      data-html="true"
      data-placement="top"
      data-container="body"
    >
      {{ timeFormated(finishedTime) }}
    </time>
  </div>
</template>
