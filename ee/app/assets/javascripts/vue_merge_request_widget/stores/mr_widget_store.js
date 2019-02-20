import CEMergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';
import { filterByKey } from 'ee/vue_shared/security_reports/store/utils';
import { mapApprovalsResponse, mapApprovalRulesResponse } from '../mappers';

export default class MergeRequestStore extends CEMergeRequestStore {
  constructor(data) {
    super(data);

    const blobPath = data.blob_path || {};
    this.headBlobPath = blobPath.head_path || '';
    this.baseBlobPath = blobPath.base_path || '';
    this.sast = data.sast || {};
    this.sastContainer = data.sast_container || {};
    this.dast = data.dast || {};
    this.dependencyScanning = data.dependency_scanning || {};
    this.sastHelp = data.sast_help_path;
    this.sastContainerHelp = data.sast_container_help_path;
    this.dastHelp = data.dast_help_path;
    this.dependencyScanningHelp = data.dependency_scanning_help_path;
    this.vulnerabilityFeedbackPath = data.vulnerability_feedback_path;
    this.vulnerabilityFeedbackHelpPath = data.vulnerability_feedback_help_path;
    this.approvalsHelpPath = data.approvals_help_path;
    this.securityReportsPipelineId = data.pipeline_id;
    this.canCreateFeedback = data.can_create_feedback || false;

    this.initCodeclimate(data);
    this.initPerformanceReport(data);
    this.licenseManagement = data.license_management;
  }

  setData(data, isRebased) {
    this.initGeo(data);
    this.initApprovals(data);

    super.setData(data, isRebased);
  }

  initGeo(data) {
    this.isGeoSecondaryNode = this.isGeoSecondaryNode || data.is_geo_secondary_node;
    this.geoSecondaryHelpPath = this.geoSecondaryHelpPath || data.geo_secondary_help_path;
  }

  initApprovals(data) {
    this.isApproved = this.isApproved || false;
    this.approvals = this.approvals || null;
    this.approvalRules = this.approvalRules || [];
    this.approvalsPath = data.approvals_path || this.approvalsPath;
    this.approvalsRequired = data.approvalsRequired || Boolean(this.approvalsPath);
    this.apiApprovalsPath = data.api_approvals_path || this.apiApprovalsPath;
    this.apiApprovalSettingsPath = data.api_approval_settings_path || this.apiApprovalSettingsPath;
    this.apiApprovePath = data.api_approve_path || this.apiApprovePath;
    this.apiUnapprovePath = data.api_unapprove_path || this.apiUnapprovePath;
  }

  setApprovals(data) {
    this.approvals = mapApprovalsResponse(data);
    this.approvalsLeft = !!data.approvals_left;
    if (gon.features.approvalRules) {
      this.isApproved = data.approved || false;
      this.preventMerge = !this.isApproved;
    } else {
      this.isApproved = !this.approvalsLeft || false;
      this.preventMerge = this.approvalsRequired && this.approvalsLeft;
    }
  }

  setApprovalRules(data) {
    this.approvalRules = mapApprovalRulesResponse(data.rules, this.approvals);
  }

  initCodeclimate(data) {
    this.codeclimate = data.codeclimate;
    this.codeclimateMetrics = {
      newIssues: [],
      resolvedIssues: [],
    };
  }

  initPerformanceReport(data) {
    this.performance = data.performance;
    this.performanceMetrics = {
      improved: [],
      degraded: [],
    };
  }

  compareCodeclimateMetrics(headIssues, baseIssues, headBlobPath, baseBlobPath) {
    const parsedHeadIssues = MergeRequestStore.parseCodeclimateMetrics(headIssues, headBlobPath);
    const parsedBaseIssues = MergeRequestStore.parseCodeclimateMetrics(baseIssues, baseBlobPath);

    this.codeclimateMetrics.newIssues = filterByKey(
      parsedHeadIssues,
      parsedBaseIssues,
      'fingerprint',
    );
    this.codeclimateMetrics.resolvedIssues = filterByKey(
      parsedBaseIssues,
      parsedHeadIssues,
      'fingerprint',
    );
  }

  comparePerformanceMetrics(headMetrics, baseMetrics) {
    const headMetricsIndexed = MergeRequestStore.normalizePerformanceMetrics(headMetrics);
    const baseMetricsIndexed = MergeRequestStore.normalizePerformanceMetrics(baseMetrics);

    const improved = [];
    const degraded = [];

    Object.keys(headMetricsIndexed).forEach(subject => {
      const subjectMetrics = headMetricsIndexed[subject];
      Object.keys(subjectMetrics).forEach(metric => {
        const headMetricData = subjectMetrics[metric];

        if (baseMetricsIndexed[subject] && baseMetricsIndexed[subject][metric]) {
          const baseMetricData = baseMetricsIndexed[subject][metric];
          const metricDirection =
            'desiredSize' in headMetricData && headMetricData.desiredSize === 'smaller' ? -1 : 1;
          const metricData = {
            name: metric,
            path: subject,
            score: headMetricData.value,
            delta: headMetricData.value - baseMetricData.value,
          };

          if (metricData.delta !== 0) {
            if (metricDirection > 0) {
              improved.push(metricData);
            } else {
              degraded.push(metricData);
            }
          }
        }
      });
    });

    this.performanceMetrics = { improved, degraded };
  }

  // normalize performance metrics by indexing on performance subject and metric name
  static normalizePerformanceMetrics(performanceData) {
    const indexedSubjects = {};
    performanceData.forEach(({ subject, metrics }) => {
      const indexedMetrics = {};
      metrics.forEach(({ name, ...data }) => {
        indexedMetrics[name] = data;
      });
      indexedSubjects[subject] = indexedMetrics;
    });

    return indexedSubjects;
  }

  static parseCodeclimateMetrics(issues = [], path = '') {
    return issues.map(issue => {
      const parsedIssue = {
        ...issue,
        name: issue.description,
      };

      if (issue.location) {
        let parseCodeQualityUrl;

        if (issue.location.path) {
          parseCodeQualityUrl = `${path}/${issue.location.path}`;
          parsedIssue.path = issue.location.path;

          if (issue.location.lines && issue.location.lines.begin) {
            parsedIssue.line = issue.location.lines.begin;
            parseCodeQualityUrl += `#L${issue.location.lines.begin}`;
          } else if (
            issue.location.positions &&
            issue.location.positions.begin &&
            issue.location.positions.begin.line
          ) {
            parsedIssue.line = issue.location.positions.begin.line;
            parseCodeQualityUrl += `#L${issue.location.positions.begin.line}`;
          }

          parsedIssue.urlPath = parseCodeQualityUrl;
        }
      }

      return parsedIssue;
    });
  }
}
