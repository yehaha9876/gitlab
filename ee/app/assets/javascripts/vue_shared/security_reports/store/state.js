export default {
  type: '',

  summaryCounts: {
    new: 0,
    fixed: 0,
  },

  blobPath: {
    head: null,
    base: null,
  },

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
  },

  sastContainer: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    approved: [],
    unapproved: [],
    vulnerabilities: [],
  },

  dast: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
  },
};
