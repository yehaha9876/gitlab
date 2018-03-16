<script>
  /**
   * Renders SAST body text
   * [priority]: [name] in [link] : [line]
   */
  import ReportLink from './report_link.vue';

  export default {
    name: 'SastIssueBody',
    props: {
      issue: {
        type: Object,
        required: true,
      },

      issueIndex: {
        type: Number,
        required: true,
      },

      modalTargetId: {
        type: String,
        required: true,
      },
    },

    components: {
      ReportLink,
    },

    methods: {
      openDastModal() {
        this.$emit('openDastModal', this.issue, this.issueIndex);
      },
    },
  };
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text append-right-5">
      <template v-if="issue.priority">{{ issue.priority }}:</template>

      <button
        type="button"
        @click="openDastModal()"
        data-toggle="modal"
        class="js-modal-dast btn-link btn-blank text-left break-link"
        :data-target="modalTargetId"
      >
        {{ issue.name }}
      </button>
    </div>

    <report-link :issue="issue" />
  </div>
</template>
