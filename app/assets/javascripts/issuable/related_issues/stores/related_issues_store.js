import {
  FETCH_SUCCESS_STATUS,
  FETCH_ERROR_STATUS,
} from '../constants';
import { assembleDisplayIssuableReference } from '../../../lib/utils/issuable_reference_utils';

class RelatedIssuesStore {
  constructor() {
    this.state = {
      // Stores issue objects that we can lookup by reference
      issueMap: {},
      // Stores references to the actual known related issues
      relatedIssues: [],
      // Stores references to the "staging area" related issues that are planned to be added
      pendingRelatedIssues: [],
    };
  }

  getIssue(id, namespacePath, projectPath) {
    const issue = this.state.issueMap[id];

    let reference = issue ? issue.reference : id;
    let displayReference = reference;
    if (issue && issue.fetchStatus === FETCH_SUCCESS_STATUS) {
      reference = assembleDisplayIssuableReference(issue);
      displayReference = assembleDisplayIssuableReference(
        issue,
        namespacePath,
        projectPath,
      );
    }

    const fetchStatus = issue ? issue.fetchStatus : FETCH_ERROR_STATUS;

    return {
      id: String(id),
      reference,
      displayReference,
      path: issue && issue.path,
      title: issue && issue && issue.title,
      state: issue && issue.state,
      fetchStatus,
      canRemove: issue && issue.destroy_relation_path && issue.destroy_relation_path.length > 0,
    };
  }

  getIssues(ids, namespacePath, projectPath) {
    return ids.map(id =>
      this.getIssue(id, namespacePath, projectPath));
  }

  addToIssueMap(reference, issue) {
    this.state.issueMap = {
      ...this.state.issueMap,
      [reference]: issue,
    };
  }

  setRelatedIssues(value) {
    this.state.relatedIssues = value;
  }

  setPendingRelatedIssues(issues) {
    this.state.pendingRelatedIssues = issues;
  }
}

export default RelatedIssuesStore;
