<script>
  import { __ } from '~/locale';
  import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
  import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
  import IssuesBlock from './report_issues.vue';
  import {
    LOADING,
    ERROR,
    SUCCESS,
  } from '../store/constants';

  export default {
    name: 'ReportSection',
    components: {
      IssuesBlock,
      LoadingIcon,
      StatusIcon,
    },
    props: {

      // security | codequality | performance | docker
      type: {
        type: String,
        required: true,
      },
      // loading | success | error
      status: {
        type: String,
        required: true,
      },
      loadingText: {
        type: String,
        required: true,
      },
      errorText: {
        type: String,
        required: true,
      },
      successText: {
        type: String,
        required: true,
      },
      unresolvedIssues: {
        type: Array,
        required: false,
        default: () => ([]),
      },
      resolvedIssues: {
        type: Array,
        required: false,
        default: () => ([]),
      },
      neutralIssues: {
        type: Array,
        required: false,
        default: () => ([]),
      },
      allIssues: {
        type: Array,
        required: false,
        default: () => ([]),
      },
      infoText: {
        type: [String, Boolean],
        required: false,
        default: false,
      },
      hasIssues: {
        type: Boolean,
        required: true,
      },
    },

    data() {
      return {
        collapseText: __('Expand'),
        isCollapsed: true,
        isFullReportVisible: false,
      };
    },

    computed: {
      isLoading() {
        return this.status === LOADING;
      },
      loadingFailed() {
        return this.status === ERROR;
      },
      isSuccess() {
        return this.status === SUCCESS;
      },
      statusIconName() {
        if (this.loadingFailed ||
          this.unresolvedIssues.length ||
          this.neutralIssues.length) {
          return 'warning';
        }
        return 'success';
      },
    },

    methods: {
      toggleCollapsed() {
        this.isCollapsed = !this.isCollapsed;

        const text = this.isCollapsed ? __('Expand') : __('Collapse');
        this.collapseText = text;
      },
      openFullReport() {
        this.isFullReportVisible = true;
      },
    },
  };
</script>
<template>
  <section class="report-block mr-widget-section">

    <div
      v-if="isLoading"
      class="media"
    >
      <div
        class="mr-widget-icon"
      >
        <loading-icon />
      </div>
      <div
        class="media-body"
      >
        {{ loadingText }}
      </div>
    </div>

    <div
      v-else-if="isSuccess"
      class="media"
    >
      <status-icon
        :status="statusIconName"
      />

      <div
        class="media-body space-children"
      >
        <span
          class="js-code-text"
        >
          {{ successText }}
        </span>

        <button
          type="button"
          class="js-collapse-btn btn bt-default pull-right btn-sm"
          v-if="hasIssues"
          @click="toggleCollapsed"
        >
          {{ collapseText }}
        </button>
      </div>
    </div>

    <div
      class="report-block-container"
      v-show="!isCollapsed"
    >
      <slot name="body">
        <p
          v-if="infoText"
          v-html="infoText"
          class="js-mr-code-quality-info prepend-left-10 report-block-info"
        >
        </p>

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

        <button
          v-if="allIssues.length && !isFullReportVisible"
          type="button"
          class="btn-link btn-blank prepend-left-10 js-expand-full-list break-link"
          @click="openFullReport"
        >
          {{ s__("ciReport|Show complete code vulnerabilities report") }}
        </button>
      </slot>
    </div>
    <div
      v-else-if="loadingFailed"
      class="media"
    >
      <status-icon status="notfound" />
      <div class="media-body">
        {{ errorText }}
      </div>
    </div>
  </section>
</template>
