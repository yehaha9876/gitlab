<script>
  import { mapActions, mapState, mapGetters } from 'vuex';
  import ReportSection from './report_section.vue';
  import {
    CI_VIEW,
    MR_WIDGET,
    SAST,
    DAST,
    SAST_CONTAINER,
  } from '../store/constants';
  import store from '../store';
  import LoadingRow from './loading_row.vue';
  import ErrorRow from './error_row.vue';
  import IssuesList from './issues_list.vue';
  import ReportSection from './report_section.vue';

  export default {
    store,
    components: {
      ReportSection,
      IssuesList,
      LoadingRow,
      ErrorRow,
    },
    props: {
      headBlobPath: {
        type: String,
        required: false,
        default: null,
      },
      baseBlobPath: {
        type: String,
        required: false,
        default: null,
      },
      type: {
        type: String,
        required: true,
      },
      sastHeadPath: {
        type: String,
        required: false,
        default: null,
      },
      sastBasePath: {
        type: String,
        required: false,
        default: null,
      },
      dastHeadPath: {
        type: String,
        required: false,
        default: null,
      },
      dastBasePath: {
        type: String,
        required: false,
        default: null,
      },
      sastContainerHeadPath: {
        type: String,
        required: false,
        default: null,
      },
      sastContainerBasePath: {
        type: String,
        required: false,
        default: null,
      },
    },
    sast: SAST,
    dast: DAST,
    sastContainer: SAST_CONTAINER,

    methods: {
      ...mapActions([
        'setAppType',
        'setHeadBlobPath',
        'setBaseBlobPath',
        'setSastHeadPath',
        'setSastBasePath',
        'setSastContainerHeadPath',
        'setSastContainerBasePath',
        'setDastHeadPath',
        'setDastBasePath',
        'fetchSastReports',
        'fetchSastContainerReports',
        'fetchDastReports',
      ]),
      checkReportStatus(loading, error) {
        if (loading) {
          return 'loading';
        } else if (error) {
          return 'error';
        }

        return 'success';
      },

      translateText(type) {
        return {
          error: sprintf(s__('ciReport|Failed to load %{reportName} report'), {
            reportName: type,
          }),
          loading: sprintf(s__('ciReport|Loading %{reportName} report'), {
            reportName: type,
          }),
        };
      },
    },

    computed: {
      ...mapState(['sast', 'sastContainer', 'dast']),
      ...mapGetters([
        'isCIView',
        'isMRWidget',
        'shouldRenderSastContainer',
        'shouldRenderSast',
        'shouldRenderDast',
        'sastText',
        'sastContainerText',
        'dastText',
        'summaryText',
      ]),

      sastContainerInformationText() {
        return sprintf(
          s__(
            'ciReport|Unapproved vulnerabilities (red) can be marked as approved. %{helpLink}',
          ),
          {
            helpLink: `<a href="https://gitlab.com/gitlab-org/clair-scanner#example-whitelist-yaml-file" target="_blank" rel="noopener noreferrer nofollow">
                ${s__('ciReport|Learn more about whitelisting')}
              </a>`,
          },
          false,
        );
      },
    },

    created() {
      // update the store with the received props
      this.setAppType(this.type);

      if (this.headBlobPath) {
        this.setHeadBlobPath(this.headBlobPath);
      }

      if (this.baseBlobPath) {
        this.setBaseBlobPath(this.baseBlobPath);
      }

      if (this.sastHeadPath) {
        this.setSastHeadPath(this.sastHeadPath);
      }

      if (this.sastBasePath) {
        this.setSastBasePath(this.sastBasePath);
      }

      if (this.sastContainerBasePath) {
        this.setSastContainerBasePath(this.sastContainerBasePath);
      }

      if (this.sastContainerHeadPath) {
        this.setSastContainerHeadPath(this.sastContainerHeadPath);
      }

      if (this.dastHeadPath) {
        this.setDastHeadPath(this.dastHeadPath);
      }

      if (this.dastBasePath) {
        this.setDastBasePath(this.dastBasePath);
      }

      // Should make requests
      if (this.shouldRenderSast) {
        this.fetchSastReports();
      }

      if (this.shouldRenderSastContainer) {
        this.fetchSastContainerReports();
      }

      if (this.shouldRenderDast) {
        this.fetchDastReports();
      }
    },
  };
</script>
<template>
  <div>
    <!-- render ungrouped -->
    <div
      class="pipeline-tab-content"
      v-if="isCiView"
    >
      <report-section
        v-if="shouldRenderSast"
        class="js-sast-widget"
        :type="sast"
        :status="checkReportStatus(sast.isLoading, sast.hasError)"
        :loading-text="translateText('security').loading"
        :error-text="translateText('security').error"
        :success-text="sastText"
        :unresolved-issues="sast.newIssues"
        :resolved-issues="sast.resolvedIssues"
        :all-issues="sast.allIssues"
      />

      <report-section
        v-if="shouldRenderSastContainer"
        class="js-sast-container-widget"
        :type="sastContainer"
        :status="checkReportStatus(sastContainer.isLoading, sastContainer.hasError)"
        :loading-text="translateText('security').loading"
        :error-text="translateText('security').error"
        :success-text="sastContainerText"
        :unresolved-issues="sastContainer.unapproved"
        :neutral-issues="sastContainer.approved"
        :has-issues="sastContainer.approved.length > 0 || dast.newIssues.length > 0"
        :info-text="sastContainerInformationText()"
      />

      <report-section
        class="js-dast-widget"
        v-if="shouldRenderDast"
        :type="dast"
        :status="checkReportStatus(dast.isLoading, dast.hasError)"
        :loading-text="translateText('security').loading"
        :error-text="translateText('security').error"
        :success-text="dastText"
        :unresolved-issues="dast.newIssues"
        :resolved-issues="dast.resolvedIssues"
        :has-issues="dast.resolvedIssues.length > 0 || dast.newIssues.length > 0"
      />
    </div>

    <!-- Render Grouped -->
    <report-section
      v-else-if="isMRWidget"
      status="success"
      :success-text="summaryText"
    >
      <div slot="body">
        <template v-if="shouldRenderSast">
          <loading-row v-if="sast.isLoading" />
          <error-row v-else-if="sast.hasError" />

          <template v-else>
            {{ sastText }}

            <issues-list
              :unresolved-issues="sast.newIssues"
              :resolved-issues="sast.resolvedIssues"
              :all-issues="sast.allIssues"
              :type="options.sast"
            />
          </template>

        </template>

        <template v-if="hasSastContainer">
          <loading-row v-if="sastContainer.isLoading" />
          <error-row v-else-if="sastContainer.hasError" />

          <template v-else>
            {{ sastContainerText }}
            <div v-html="sastContainerInformationText"></div>

            <issues-list
              :unresolved-issues="sastContainer.unapproved"
              :neutral-issues="sastContainer.approved"
              :type="options.sastContainer"
            />
          </template>
        </template>

        <template v-if="hasDast">
          <loading-row v-if="dast.isLoading" />
          <error-row v-else-if="dast.hasError" />

          <template v-else>
            {{ dastText }}
            <issues-list
              :unresolved-issues="dast.newIssues"
              :resolved-issues="dast.resolvedIssues"
              :type="options.dast"
            />
          </template>
        </template>
      </div>
    </report-section>
  </div>
</template>
