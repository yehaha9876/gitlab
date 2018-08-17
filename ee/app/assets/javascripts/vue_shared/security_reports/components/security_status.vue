<script>
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';

// TODO: Make this an action
// TODO: Stop faking the data
const fetchReportStatusAction = () => new Promise((resolve, reject) => {
  const dummyData = {
    is_secure: false,
    pipeline_url: 'https://gitlab.com/',
  };
  setTimeout(resolve, 4000, { data: dummyData });
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
      isLoading: true,
      data: {},
    };
  },
  computed: {
    reportUrl() {
      return this.data.pipeline_url;
    },
    status() {
      if (this.isLoading) {
        return 'loading';
      }

      return this.data.is_secure ? 'success' : 'warning';
    },
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
    :title="s__('ciReport|Security Report')"
    :href="reportUrl"
    data-placement="bottom"
  >
    <status-icon
      :status="status"
      class="temp-class"
    />
  </a>
</template>

<style scoped>
/* TODO: This is a bit nonsensical, find a more sensible approach */
.temp-class {
  display: inline-block !important;
  margin: 0;
}
</style>

