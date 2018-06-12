<script>
export default {
  name: 'ReportIssueLink',
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    issueLink() {
      return this.issue.line ? `${this.issue.urlPath}#L${this.issue.line}` : this.issue.urlPath;
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description-link">
    in

    <a
      v-if="issue.urlPath"
      :href="issueLink"
      target="_blank"
      rel="noopener noreferrer nofollow"
      class="break-link"
    >
      {{ issue.path }}<template v-if="issue.line">:{{ issue.line }}</template>
    </a>
    <template v-else>
      {{ issue.path }}<template v-if="issue.line">:{{ issue.line }}</template>
    </template>
  </div>
</template>
