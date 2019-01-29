import { s__ } from '~/locale';

export default () => ({
  summaryCounts: {
    added: 0,
    fixed: 0,
    existing: 0,
  },

  blobPath: {
    head: null,
    base: null,
  },

  vulnerabilityFeedbackPath: null,
  vulnerabilityFeedbackHelpPath: null,
  pipelineId: null,
  canCreateIssuePermission: false,
  canCreateFeedbackPermission: false,

  sast: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    allIssues: [],
    dismissedIssues: [],
  },
  sastContainer: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    dismissedIssues: [],
  },
  dast: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    dismissedIssues: [],
  },

  dependencyScanning: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    // TODO: Do we still need allIssues?
    allIssues: [],
    dismissedIssues: [],
  },

  modal: {
    title: null,

    // Dynamic data rendered for each issue
    data: {
      description: {
        value: null,
        text: s__('ciReport|Description'),
        isLink: false,
      },
      identifiers: {
        value: [],
        text: s__('ciReport|Identifiers'),
        isLink: false,
      },
      file: {
        value: null,
        url: null,
        text: s__('ciReport|File'),
        isLink: true,
      },
      className: {
        value: null,
        text: s__('ciReport|Class'),
        isLink: false,
      },
      methodName: {
        value: null,
        text: s__('ciReport|Method'),
        isLink: false,
      },
      namespace: {
        value: null,
        text: s__('ciReport|Namespace'),
        isLink: false,
      },
      severity: {
        value: null,
        text: s__('ciReport|Severity'),
        isLink: false,
      },
      confidence: {
        value: null,
        text: s__('ciReport|Confidence'),
        isLink: false,
      },
      links: {
        value: [],
        text: s__('ciReport|Links'),
        isLink: false,
      },
      instances: {
        value: [],
        text: s__('ciReport|Instances'),
        isLink: false,
      },
    },
    learnMoreUrl: null,

    vulnerability: {
      isDismissed: false,
      hasIssue: false,
    },

    isCreatingNewIssue: false,
    isDismissingIssue: false,

    error: null,
  },
});
