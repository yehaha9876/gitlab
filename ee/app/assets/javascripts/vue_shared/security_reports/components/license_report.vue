<script>
import { sprintf, s__, n__ } from '~/locale';
import ReportSection from './report_section.vue';
import reportsMixin from '../mixins/reports_mixin';

export default {
  components: { ReportSection },
  mixins: [reportsMixin],
  props: {
    basePath: {
      type: String,
      required: false
    },
    headPath: {
      type: String,
      required: true
    },
    //TODO: Generate these in the component
    mockLicenseReport: {
      type: Array,
      required: false
    }
  },
  data() {
    return {
      isLoading: false,
      loadingFailed: false
    };
  },
  computed: {
    hasLicenseReportIssues() {
      return this.licenseReport && this.licenseReport.length > 0;
    },
    licenseReportStatus() {
      return this.checkReportStatus(this.isLoading, this.loadingFailed)
    },
    licenseReport() {
      // TODO: stop faking it
      return this.$props.mockLicenseReport
    },
    licenseReportText() {
      if (this.licenseReport.length > 0) {
        return sprintf(s__('ciReport|License management detected %{licenseInfo}'), {
          licenseInfo: n__('%d new license', '%d new licenses', this.licenseReport.length),
        });
      }

      return s__('ciReport|License management detected no new licenses');
    },
  },
  created() {
    const { headPath, basePath } = this.$props;

    // TODO: Work out the best way to fetch these reports
    return;

    if (headPath && basePath) {
      this.fetchLicenseReport();
    } else if (headPath) {
      this.fetchNewLicenses();
    }
  }
}
</script>
<template>
  <report-section
    :error-text="s__('ciReport|Failed to load license management report')"
    :has-issues="hasLicenseReportIssues"
    :loading-text="s__('ciReport|Loading license management report')"
    :status="licenseReportStatus"
    :success-text="licenseReportText"
    :unresolved-issues="licenseReport"
    class="js-license-report-widget mr-widget-border-top"
    type="license"
  />
</template>
