export default () => ({
  isLoadingVulnerabilities: false,
  isLoadingVulnerabilitiesCount: false,
  pageInfo: {},
  vulnerabilities: [],
  vulnerabilitiesCount: {},
  modal: {
    data: {
      description: { text: 'Description' },
      project: {
        text: 'Project',
        isLink: true,
      },
      file: { text: 'File' },
      identifiers: { text: 'Identifiers' },
      severity: { text: 'Severity' },
      confidence: { text: 'Confidence' },
      solution: { text: 'Solution' },
      links: { text: 'Links' },
      instances: { text: 'Instances' },
    },
  },
  errorLoadingVulnerabilities: false,
});
