<script>
import Icon from '~/vue_shared/components/ci_icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';

// TODO: Make this an action
// TODO: Stop faking the data
const fetchReportStatusAction = () => new Promise((resolve, reject) => {
  const dummyData = {
   "is_secure": false,
   "pipeline_url": "https://gitlab.com/"
  };
  setTimeout(resolve, 4000, { data: dummyData });
});

export default {
  components: {
    Icon,
  },
  directives: {
    Tooltip,
  },
  props: {
    commitShortSha: {
      type: String,
      required: true,
    }
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
    reportStatus() {
      return this.data.is_secure ? 'success' : 'warning';
    },
    iconStatus() {
      return {
        icon: `status_${this.reportStatus}`,
        group: this.reportStatus
      }
    }
  },
  methods: {
    fetchReportStatus() {
      this.isLoading = true;

      fetchReportStatusAction(this.commitShortSha)
        .then(response => {
          this.isLoading = false;
          this.data = response.data
        })
        .catch(error => {
          //TODO: Handle the error
        })
    }
  },
  created() {
    this.fetchReportStatus()
  }
};
</script>

<template>
  <a
    v-tooltip
    v-if="!isLoading"
    data-placement="bottom"
    :title="s__('ciReport|Security Report')"
    :href="reportUrl"
  >
    <icon
      :status="iconStatus"
      :size="24"
    />
  </a>
</template>
