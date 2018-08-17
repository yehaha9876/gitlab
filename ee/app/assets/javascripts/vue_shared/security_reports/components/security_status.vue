<script>
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';

// TODO: Stop faking the data
// TODO: Handle a case where the commit/pipeline doesn't have security reports
const fetchReportStatusAction = () => new Promise((resolve, reject) => {
  const dummyData = {
    is_secure: false,
    pipeline_url: 'https://gitlab.com/',
  };
  setTimeout(reject, 4000, { data: dummyData });
});

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
      if (this.isLoading) { return 'loading' }
      if (this.data.is_secure) { return 'success' }
      return 'warning';
    },
    hasReports() {
      // TODO: Come back to this when we have real data, this may not suffice
      // If the data object is empty, return false
      return Object.keys(this.data).length > 0;
    }
  },
  created() {
    this.fetchReportStatus();
  },
  methods: {
    fetchReportStatus() {
      this.isLoading = true;

      fetchReportStatusAction(this.commitShortSha)
        .then(response => {
          this.isLoading = false;
          this.hasError = false;
          this.data = response.data;
        })
        .catch(error => {
          this.isLoading = false;
          this.hasError = true;
          // TODO: Handle the error
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

