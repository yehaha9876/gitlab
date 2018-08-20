<script>
import axios from '~/lib/utils/axios_utils';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import { ICON_WARNING, ICON_SUCCESS } from '~/reports/constants';

export default {
  components: {
    StatusIcon,
  },
  directives: {
    Tooltip,
  },
  props: {
    commitShortSha: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hasError: false,
      isLoading: false,
      data: {},
    };
  },
  computed: {
    status() {
      if (this.isLoading) { return 'loading'; }
      if (this.data.is_secure) { return ICON_SUCCESS; }
      return ICON_WARNING;
    },
    hasReports() {
      // TODO: Come back to this when we have real data, this may not suffice
      // If the data object is empty, return false
      return Object.keys(this.data).length > 0;
    },
  },
  created() {
    this.fetchReportStatus();
  },
  methods: {
    fetchReportStatus() {
      // TODO: Swap this for the real url when it arrives
      const url = `/notarealendpoint/${this.commitShortSha}`;
      this.isLoading = true;

      axios.get(url)
        .then(response => {
          this.isLoading = false;
          this.hasError = false;
          this.data = response.data || {};
        })
        .catch(() => {
          // TODO: Handle the error
          this.isLoading = false;
          this.hasError = true;
        });
    },
  },
};
</script>

<template>
  <a
    v-tooltip
    v-if="hasReports || isLoading"
    :title="s__('ciReport|Security Report')"
    :href="data.pipeline_url"
    data-placement="bottom"
  >
    <status-icon
      :status="status"
      class="temp-class"
    />
  </a>
  <span v-else>–</span>
</template>

<style scoped>
/* TODO: This is a bit nonsensical, find a more sensible approach */
.temp-class {
  display: inline-block !important;
  margin: 0;
}
</style>

