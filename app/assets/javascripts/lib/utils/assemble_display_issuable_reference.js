// Transform `foo/bar#123` into `#123` given
// `currentNamespacePath = 'foo'` and `currentProjectPath = 'bar'`
function assembleDisplayIssuableReference(issue, currentNamespacePath, currentProjectPath) {
  let necessaryReference = `#${issue.iid}`;
  if (issue.project_path && currentProjectPath !== issue.project_path) {
    necessaryReference = issue.project_path + necessaryReference;
  }
  if (issue.namespace_full_path && currentNamespacePath !== issue.namespace_full_path) {
    necessaryReference = `${issue.namespace_full_path}/${necessaryReference}`;
  }

  return necessaryReference;
}

export default assembleDisplayIssuableReference;
