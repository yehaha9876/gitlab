import _ from 'underscore';

export const dashboardError = state =>
  state.errorLoadingVulnerabilities && state.errorLoadingVulnerabilitiesCount;
export const dashboardListError = state =>
  state.errorLoadingVulnerabilities && !state.errorLoadingVulnerabilitiesCount;
export const dashboardCountError = state =>
  !state.errorLoadingVulnerabilities && state.errorLoadingVulnerabilitiesCount;

export const getFilteredVulnerabilitiesHistory = state => name => {
  const history = state.vulnerabilitiesHistory[name.toLowerCase()];
  const days = state.vulnerabilitiesHistoryDayRange;

  if (!history) {
    return [];
  }

  const data = Object.entries(history);
  const currentDate = new Date();
  const startDate = new Date();

  startDate.setDate(currentDate.getDate() - days);

  return _.filter(data, date => {
    const parsedDate = Date.parse(date[0]);
    return parsedDate > startDate;
  });
};

export default () => {};
