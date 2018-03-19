import { s__, n__, __ } from '~/locale';

export const parseCodeclimateMetrics = (issues = [], path = '') =>
  issues.map(issue => {
    const parsedIssue = Object.assign({}, issue, {
      name: issue.description,
    });

    if (issue.location) {
      if (issue.location.path) {
        parsedIssue.path = issue.location.path;

        if (issue.location.lines && issue.location.lines.begin) {
          parsedIssue.line = issue.location.lines.begin;
          parsedIssue.urlPath = `${path}/${issue.location.path}`;
        } else {
          parsedIssue.urlPath = `${path}/${issue.location.path}#L${
            issue.location.lines.begin
          }`;
        }
      }
    }

    return parsedIssue;
  });

/**
 * Maps SAST:
 * { tool: String, message: String, url: String , cve: String ,
 * file: String , solution: String, priority: String }
 * to contain:
 * { name: String, path: String, line: String, urlPath: String, priority: String }
 * @param {Array} issues
 * @param {String} path
 */
export const parseSastIssues = (issues = [], path = '') =>
  issues.map(issue =>
    Object.assign({}, issue, {
      name: issue.name,
      path: issue.file ? `${path}/${issue.file}` : null,
      urlPath: issue.line
        ? `${path}/${issue.file}#L${issue.line}`
        : `${path}/${issue.file}`,
    }),
  );

/**
 * Compares two arrays by the given key and returns the difference
 *
 * @param {Array} firstArray
 * @param {Array} secondArray
 * @param {String} key
 * @returns {Array}
 */
export const filterByKey = (firstArray = [], secondArray = [], key = '') =>
  firstArray.filter(item => !secondArray.find(el => el[key] === item[key]));

/**
 * Parses DAST results into a common format to allow to use the same Vue component
 * And adds an external link
 *
 * @param {Array} data
 * @returns {Array}
 */
export const parseSastContainer = (data = []) =>
  data.map(el => ({
    name: el.vulnerability,
    priority: el.severity,
    path: el.namespace,
    // external link to provide better description
    nameLink: `https://cve.mitre.org/cgi-bin/cvename.cgi?name=${
      el.vulnerability
    }`,
    ...el,
  }));

export const headBaseSummaryTextBuilder = (
  type = '',
  added = 0,
  fixed = 0,
  all = 0,
) => {
  const text = [type];

  if (added === 0 && fixed === 0 && all === 0) {
    text.push(s__('ciReport|detected no new security vulnerabilities'));
  }

  if (added === 0 && fixed === 0 && all !== 0) {
    text.push(s__('ciReport|SAST detected no new security vulnerabilities'));
  }

  if (added > 0) {
    return n__(
      'detected %d new vulnerability',
      'detected %d new vulnerabilities',
      added,
    );
  }

  if (added > 0 && fixed > 0) {
    text.push(__('and'));
  }

  if (fixed > 0) {
    text.push(
      n__(
        'detected %d fixed vulnerability',
        'detected %d fixed vulnerabilities',
        fixed,
      ),
    );
  }

  return text.join(' ');
};

export const headSummaryTextBuilder = (type = '', added = 0) => {
  const text = [type];

  if (added === 0) {
    text.push(s__('ciReport|detected no security vulnerabilities'));
  }

  if (added > 0) {
    text.push(
      n__('detected %d vulnerability', 'detected %d vulnerabilities', added),
    );
  }

  return text.join(' ');
};
