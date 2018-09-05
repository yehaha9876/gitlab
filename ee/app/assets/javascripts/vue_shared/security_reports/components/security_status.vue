<script>
import axios from '~/lib/utils/axios_utils';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import { ICON_WARNING, ICON_SUCCESS } from '~/reports/constants';
import {
  parseDastIssues,
  parseDependencyScanningIssues,
  parseSastContainer,
  parseSastIssues,
} from 'ee/vue_shared/security_reports/store/utils';

export default {
  components: {
    StatusIcon,
  },
  directives: {
    Tooltip,
  },
  props: {
    sastPath: {
      type: String,
      required: false,
      default: null,
    },
    dependencyScanningPath: {
      type: String,
      required: false,
      default: null,
    },
    containerScanningPath: {
      type: String,
      required: false,
      default: null,
    },
    dastPath: {
      type: String,
      required: false,
      default: null,
    },
    vulnerabilityFeedbackPath: {
      type: String,
      required: true,
    },
    pipelineSecurityPath: {
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
      if (this.isLoading) {
        return 'loading';
      }
      if (this.isSecure) {
        return ICON_SUCCESS;
      }
      return ICON_WARNING;
    },
  },
  created() {
    this.fetchReportStatus();
  },
  methods: {
    hasUnresolvedSastIssues(vulnerabilityFeedbackReport) {
      if (!this.sastPath) {
        return false;
      }

      return axios.get(this.sastPath).then(res => {
        const sastReport = res.data;
        const parsed = parseSastIssues(sastReport, vulnerabilityFeedbackReport);
        return parsed.some(vuln => !vuln.isDismissed);
      });
    },

    hasUnresolvedDastIssues(vulnerabilityFeedbackReport) {
      if (!this.dastPath) {
        return false;
      }

      return axios.get(this.dastPath).then(res => {
        const dastReport = (res.data && res.data.site && res.data.site.alerts) || [];
        const parsed = parseDastIssues(dastReport, vulnerabilityFeedbackReport);
        return parsed.some(vuln => !vuln.isDismissed);
      });
    },

    hasUnresolvedContainerScanningIssues(vulnerabilityFeedbackReport) {
      if (!this.containerScanningPath) {
        return false;
      }

      return axios.get(this.containerScanningPath).then(res => {
        const containerScanningReport = (res.data && res.data.vulnerabilities) || [];
        const parsed = parseSastContainer(containerScanningReport, vulnerabilityFeedbackReport);
        return parsed.some(vuln => !vuln.isDismissed);
      });
    },

    hasUnresolvedDependencyScanningIssues(vulnerabilityFeedbackReport) {
      if (!this.dependencyScanningPath) {
        return false;
      }

      return axios.get(this.dependencyScanningPath).then(res => {
        const dependencyScanningReport = (res.data && res.data.vulnerabilities) || [];
        const parsed = parseDependencyScanningIssues(
          dependencyScanningReport,
          vulnerabilityFeedbackReport,
        );
        return parsed.some(vuln => !vuln.isDismissed);
      });
    },

    fetchReportStatus() {
      this.isLoading = true;
      this.hasError = false;

      return axios
        .get(this.vulnerabilityFeedbackPath)
        .then(res => res.data)
        .catch(() => [])
        .then(vulnerabilityFeedbackReport =>
          Promise.all([
            this.hasUnresolvedSastIssues(vulnerabilityFeedbackReport),
            this.hasUnresolvedDastIssues(vulnerabilityFeedbackReport),
            this.hasUnresolvedContainerScanningIssues(vulnerabilityFeedbackReport),
            this.hasUnresolvedDependencyScanningIssues(vulnerabilityFeedbackReport),
          ]),
        )
        .then(reports => reports.some(report => report))
        .then(hasIssues => {
          this.isSecure = !hasIssues;
          this.isLoading = false;
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
    :title="s__('ciReport|Security Report')"
    :href="pipelineSecurityPath"
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
