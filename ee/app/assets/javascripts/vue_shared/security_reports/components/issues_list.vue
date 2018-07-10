<script>
import IssuesBlock from './report_issues.vue';
import SastContainerInfo from './sast_container_info.vue';
import { SAST_CONTAINER } from '../store/constants';
import { mapState } from 'vuex';

/**
 * Renders block of issues
 */

export default {
  components: {
    IssuesBlock,
    SastContainerInfo,
  },
  sastContainer: SAST_CONTAINER,
  props: {
    unresolvedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    resolvedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    neutralIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['pipelineId']),
    unresolvedIssuesStatus() {
      return this.type === 'license' ? 'neutral' : 'failed';
    },
    fullReportLink() {
      // TODO: Make this a bit more dynamic/reliable
      return `../pipelines/${this.pipelineId}/security`;
    }
  },
};
</script>
<template>
  <div class="report-block-container">
    <sast-container-info v-if="type === $options.sastContainer" />

    <issues-block
      v-if="unresolvedIssues.length"
      :type="type"
      :status="unresolvedIssuesStatus"
      :issues="unresolvedIssues"
      class="js-mr-code-new-issues"
    />

    <issues-block
      v-if="neutralIssues.length"
      :type="type"
      :issues="neutralIssues"
      class="js-mr-code-non-issues"
      status="neutral"
    />

    <issues-block
      v-if="resolvedIssues.length"
      :type="type"
      :issues="resolvedIssues"
      class="js-mr-code-resolved-issues"
      status="success"
    />

    <a
      class="prepend-left-10"
      :href="fullReportLink"
      :title="s__('ciReport|Show complete code vulnerabilities report')"
    >
      {{ s__("ciReport|Show complete code vulnerabilities report") }}
    </a>
  </div>
</template>
