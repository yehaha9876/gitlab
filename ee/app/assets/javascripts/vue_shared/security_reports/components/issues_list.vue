<script>
import IssuesBlock from './report_issues.vue';
import SastContainerInfo from './sast_container_info.vue';
import { SAST_CONTAINER } from '../store/constants';

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
    allIssues: {
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
    unresolvedIssuesStatus() {
      return this.type === 'license' ? 'neutral' : 'failed';
    },
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

    <!-- TODO: link to the pipeline page -->
    <a
      v-if="allIssues.length"
      class="prepend-left-10"
      href="#"
    >
      {{ s__("ciReport|Show complete code vulnerabilities report") }}
    </a>
  </div>
</template>
