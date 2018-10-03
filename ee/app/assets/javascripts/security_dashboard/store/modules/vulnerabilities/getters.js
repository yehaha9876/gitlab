import { sum } from '~/lib/utils/number_utils';

export const vulnerabilitiesCountBySeverity = (state) => severity =>
  Object.values(state.vulnerabilitiesCount)
    .map(count => count[severity])
    .reduce(sum, 0);
export const vulnerabilitiesCountByReportType = (state) => type => {
  const counts = state.vulnerabilitiesCount[type];
  return counts ? Object.values(counts).reduce(sum, 0) : 0;
};
export const modal = (state) => {
  const vulnerability = state.currentVulnerability;

  return {
    title: vulnerability.name,
    data: {
      description: {
        text: 'Description',
        value: vulnerability.description,
      },
      project: {
        text: 'Project',
        isLink: true,
        value: vulnerability.project ? vulnerability.project.name_with_namespace : null,
        url: vulnerability.project ? vulnerability.project.web_url : null,
      },
      file: {
        text: 'File',
        value: vulnerability.location ? vulnerability.location.file : null,
      },
      identifiers: {
        text: 'Identifiers',
        value: vulnerability.identifiers,
      },
      severity: {
        text: 'Severity',
        value: vulnerability.severity,
      },
      confidence: {
        text: 'Confidence',
        value: vulnerability.confidence,
      },
      solution: {
        text: 'Solution',
        value: vulnerability.solution,
      },
      links: {
        text: 'Links',
        value: vulnerability.links,
      },
      instances: {
        text: 'Instances',
        value: vulnerability.instances,
      }
    }
  };
}

export default () => {};
