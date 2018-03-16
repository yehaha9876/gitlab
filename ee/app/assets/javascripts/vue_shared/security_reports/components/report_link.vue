<script>
  export default {
    name: 'ReportIssueLink',
    props: {
      issue: {
        type: Object,
        required: true,
      },
    },
  };
</script>
<template>
  <div class="report-block-list-issue-description-link">
    <template v-if="issue.path">
      in

      <a
        v-if="issue.urlPath"
        :href="issue.urlPath"
        target="_blank"
        rel="noopener noreferrer nofollow"
        class="break-link"
      >
        {{ issue.path }}<template v-if="issue.line">:{{ issue.line }}</template>
      </a>
      <template v-else>
        {{ issue.path }}<template v-if="issue.line">:{{ issue.line }}</template>
      </template>
    </template>
  </div>
</template>
