import { accumulate } from '~/lib/utils/common_utils';

export const pageInfo = state => state.pageInfo;
export const vulnerabilities = state => state.vulnerabilities || [];
export const loadingVulnerabilities = state => state.loadingVulnerabilities;
export const vulnerabilitiesCount = state => state.vulnerabilitiesCount || {};
export const loadingVulnerabilitiesCount = state => state.loadingVulnerabilitiesCount;
export const vulnerabilitiesCountBySeverity = (state, getters) => severity =>
  Object.values(getters.vulnerabilitiesCount)
    .map(count => count[severity])
    .reduce(accumulate, 0);
export const vulnerabilitiesCountByReportType = (state, getters) => type => {
  const counts = getters.vulnerabilitiesCount[type];
  return counts ? Object.values(counts).reduce(accumulate, 0) : 0;
};

export default () => {};
