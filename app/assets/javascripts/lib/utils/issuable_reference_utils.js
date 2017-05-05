const ISSUABLE_REFERENCE_REGEX = /^((?:[^\s/]+(?:\/(?!#))?)*)#(\d+)$/i;
// Matches a rough URL with some numbers on the end
const ISSUABLE_URL_REGEX = /[^.\s]+\/\d+\/?$/i;

function getReferencePieces(partialReference, namespacePath, projectPath) {
  const [
    ,
    fullNamespace = '',
    resultantIssue,
  ] = partialReference.match(ISSUABLE_REFERENCE_REGEX);
  const namespacePieces = fullNamespace.split('/');
  const resultantNamespace = namespacePieces.length > 1 ? namespacePieces.slice(0, -1).join('/') : namespacePath;
  const resultantProject = namespacePieces.slice(-1)[0] || projectPath;

  return {
    namespace: resultantNamespace,
    project: resultantProject,
    issue: resultantIssue,
  };
}

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

export {
  ISSUABLE_REFERENCE_REGEX,
  ISSUABLE_URL_REGEX,
  getReferencePieces,
  assembleDisplayIssuableReference,
};
