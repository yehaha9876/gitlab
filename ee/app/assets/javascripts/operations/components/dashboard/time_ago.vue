<script>
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
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
  },
};
</script>
<template>
  <div v-if="hasFinishedTime" class="ops-dashboard-project-time-ago">
    <icon name="clock" class="ops-dashboard-project-time-ago-icon" />

    <time v-tooltip :title="tooltipTitle(finishedTime)" data-placement="top" data-container="body">
      {{ timeFormated(finishedTime) }}
    </time>
  </div>
</template>
