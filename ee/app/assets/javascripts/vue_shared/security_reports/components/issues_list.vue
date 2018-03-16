<script>
  export default {
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
      isFullReportVisible: {
        type: Boolean,
        required: false,
        default: false,
      },
      type: {
        type: String,
        required: true,
      },
    },
  };
</script>
<template>
  <div>
    <issues-block
      class="js-mr-code-new-issues"
      v-if="unresolvedIssues.length"
      :type="type"
      status="failed"
      :issues="unresolvedIssues"
    />

    <issues-block
      class="js-mr-code-all-issues"
      v-if="isFullReportVisible"
      :type="type"
      status="failed"
      :issues="allIssues"
    />

    <issues-block
      class="js-mr-code-non-issues"
      v-if="neutralIssues.length"
      :type="type"
      status="neutral"
      :issues="neutralIssues"
    />

    <issues-block
      class="js-mr-code-resolved-issues"
      v-if="resolvedIssues.length"
      :type="type"
      status="success"
      :issues="resolvedIssues"
    />
  </div>
</template>
