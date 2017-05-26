import Vue from 'vue';
import vueResource from 'vue-resource';
import { getReferencePieces } from '../../../lib/utils/issuable_reference_utils';

Vue.use(vueResource);

class RelatedIssuesService {
  constructor(endpoint) {
    this.relatedIssuesResource = Vue.resource(endpoint);
  }

  // eslint-disable-next-line class-methods-use-this
  fetchIssueFromReference(reference, currentNamespacePath, currentProjectPath) {
    // TODO: Temporary mocking until BE `3` is in place, https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1797#todo
    const referencePieces = getReferencePieces(
      reference,
      currentNamespacePath,
      currentProjectPath,
    );
    const baseIssueEndpoint = `/${referencePieces.namespace}/${referencePieces.project}/issues/${referencePieces.issue}`;
    return Vue.http.get(`${baseIssueEndpoint}.json`)
      .then(res => res.json())
      // eslint-disable-next-line arrow-body-style
      .then((issue) => {
        return {
          namespace_full_path: referencePieces.namespace,
          project_path: referencePieces.project,
          id: issue.id,
          iid: issue.iid,
          path: baseIssueEndpoint,
          state: issue.state,
          title: issue.title,
        };
      });
  }

  fetchRelatedIssues() {
    return this.relatedIssuesResource.get();
  }

  addRelatedIssues(newIssueReferences) {
    return this.relatedIssuesResource.save({}, {
      issue_references: newIssueReferences,
    });
  }

  // eslint-disable-next-line class-methods-use-this
  removeRelatedIssue(endpoint) {
    return Vue.http.delete(endpoint);
  }
}

export default RelatedIssuesService;
