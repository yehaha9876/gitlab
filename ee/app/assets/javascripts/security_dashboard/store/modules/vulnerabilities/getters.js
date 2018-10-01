import { sum } from '~/lib/utils/number_utils';

export const pageInfo = state => state.pageInfo;
export const vulnerabilities = state => state.vulnerabilities || [];
export const isLoadingVulnerabilities = state => state.isLoadingVulnerabilities;
export const vulnerabilitiesCount = state => state.vulnerabilitiesCount || {};
export const isLoadingVulnerabilitiesCount = state => state.isLoadingVulnerabilitiesCount;
export const errorLoadingVulnerabilities = state => state.errorLoadingVulnerabilities;
export const vulnerabilitiesCountBySeverity = (state, getters) => severity =>
  Object.values(getters.vulnerabilitiesCount)
    .map(count => count[severity])
    .reduce(sum, 0);
export const vulnerabilitiesCountByReportType = (state, getters) => type => {
  const counts = getters.vulnerabilitiesCount[type];
  return counts ? Object.values(counts).reduce(sum, 0) : 0;
};

export default () => {};
