<script>
/* global Flash */

/*
`rawReferences` are separated by spaces.
Given `abc 123 zxc`, `rawReferences = ['abc', '123', 'zxc']`

Consider you are typing `abc 123 zxc` in the input and your caret position is
at position 4 right before the `123` `rawReference`. Then you type `#` and
it becomes a valid reference, `#123`, but we don't want to jump it straight into
`pendingRelatedIssues` because you could still want to type. Say you typed `999`
and now we have `#999123`. Only when you move your caret away from that `rawReference`
do we actually put it in the `pendingRelatedIssues`.

Your caret can stop touching a `rawReference` can happen in a variety of ways:

 - As you type, we only tokenize after you type a space or move with the arrow keys
 - On blur, we consider your caret not touching anything

---

 - When you click the "Add related issues"(in the `AddIssuableForm`),
   we submit the `pendingRelatedIssues` to the server and they come back as actual `relatedIssues`
 - When you click the "Cancel"(in the `AddIssuableForm`), we clear out `pendingRelatedIssues`
   and hide the `AddIssuableForm` area.

---

We validate `rawReferences` client-side on their form, not actual existentance.
We only check existence, permissions when you actually submit the `pendingRelatedIssues`

---

We avoid making duplicate requests by storing issue data in the `store -> issueMap`.
We can check for the existence in the store and the `fetchStatus` of each issue inside.
*/

import _ from 'underscore';
import eventHub from '../event_hub';
import RelatedIssuesBlock from './related_issues_block.vue';
import RelatedIssuesStore from '../stores/related_issues_store';
import RelatedIssuesService from '../services/related_issues_service';
import {
  FETCHING_STATUS,
  FETCH_SUCCESS_STATUS,
  FETCH_ERROR_STATUS,
} from '../constants';
import {
  ISSUABLE_REFERENCE_REGEX,
  ISSUABLE_URL_REGEX,
} from '../../../lib/utils/issuable_reference_utils';

export default {
  name: 'RelatedIssuesRoot',

  props: {
    endpoint: {
      type: String,
      required: true,
    },
    currentNamespacePath: {
      type: String,
      required: true,
    },
    currentProjectPath: {
      type: String,
      required: true,
    },
    canAddRelatedIssues: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
  },

  data() {
    this.store = new RelatedIssuesStore();

    return {
      state: this.store.state,
      isFormVisible: false,
      inputValue: '',
    };
  },

  components: {
    relatedIssuesBlock: RelatedIssuesBlock,
  },

  computed: {
    computedRelatedIssues() {
      return this.store.getIssues(
        this.state.relatedIssues,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
    },
    computedPendingRelatedIssues() {
      return this.store.getIssues(
        this.state.pendingRelatedIssues,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
    },
    autoCompleteSources() {
      return gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources;
    },
  },

  methods: {
    onRelatedIssueRemoveRequest(idToRemove) {
      this.store.removeRelatedIssue(idToRemove);

      this.service.removeRelatedIssue(this.state.issueMap[idToRemove].destroy_relation_path)
        .catch(() => {
          // Restore issue we were unable to delete
          this.store.setRelatedIssues(this.state.relatedIssues.concat(idToRemove));

          // eslint-disable-next-line no-new
          new Flash('An error occurred while removing related issues.');
        });
    },
    onShowAddRelatedIssuesForm() {
      this.isFormVisible = true;
    },
    onAddIssuableFormIssuableRemoveRequest(idToRemove) {
      this.store.removePendingRelatedIssue(idToRemove);
    },
    onAddIssuableFormSubmit() {
      const currentPendingIssues = this.state.pendingRelatedIssues;
      const currentRelatedIssues = this.state.relatedIssues;
      if (currentPendingIssues.length > 0) {
        const currentPendingReferences = this.computedPendingRelatedIssues.map(
          issue => issue.reference,
        );
        this.service.addRelatedIssues(currentPendingReferences)
          .then(res => res.json())
          .then(() => {
            // TODO: Wait for BE `1` so we can update accurately
            // with the response instead of the what was submitted, https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1797#todo
            this.store.setRelatedIssues(
              _.uniq(this.state.relatedIssues.concat(currentPendingIssues)),
            );
          })
          .catch(() => {
            // Something went wrong, so restore and tell them about it
            this.store.setPendingRelatedIssues(
              _.uniq(this.state.pendingRelatedIssues.concat(currentPendingIssues)),
            );
            // Remove the temporary relation
            this.store.setRelatedIssues(currentRelatedIssues);

            // eslint-disable-next-line no-new
            new Flash('An error occurred while submitting related issues.');
          });

        // Show the relation right away
        this.store.setPendingRelatedIssues([]);
        this.store.setRelatedIssues(
          _.uniq(currentRelatedIssues.concat(currentPendingIssues)),
        );
      }
    },
    onAddIssuableFormCancel() {
      this.isFormVisible = false;
      this.store.setPendingRelatedIssues([]);
      this.inputValue = '';
    },
    fetchRelatedIssues() {
      this.service.fetchRelatedIssues()
        .then(res => res.json())
        .then((issues) => {
          const relatedIssueIds = issues.map((issue) => {
            this.store.addToIssueMap(issue.id, {
              ...issue,
              fetchStatus: FETCH_SUCCESS_STATUS,
            });

            return issue.id;
          });
          this.store.setRelatedIssues(relatedIssueIds);
        })
        .catch(() => new Flash('An error occurred while fetching related issues.'));
    },

    onAddIssuableFormInput(newValue, caretPos) {
      const rawReferences = newValue.split(/\s/);

      let touchedReference;
      let iteratingPos = 0;
      const untouchedReferences = rawReferences.filter((reference) => {
        let isTouched = false;
        if (caretPos >= iteratingPos && caretPos <= (iteratingPos + reference.length)) {
          touchedReference = reference;
          isTouched = true;
        }

        // `+ 1` to factor in the missing space we split at earlier
        iteratingPos = iteratingPos + reference.length + 1;
        return !isTouched;
      });

      const results = this.processIssuableReferences(untouchedReferences);
      if (results.references.length > 0) {
        this.store.setPendingRelatedIssues(
          _.uniq(this.state.pendingRelatedIssues.concat(results.ids)),
        );
        const unprocessableString = results.unprocessableReferences.map(ref => `${ref} `).join('');
        this.inputValue = `${unprocessableString}${touchedReference}`;
      }
    },
    onAddIssuableFormBlur(newValue) {
      const rawReferences = newValue.split(/\s+/);
      const results = this.processIssuableReferences(rawReferences);
      this.store.setPendingRelatedIssues(
        _.uniq(this.state.pendingRelatedIssues.concat(results.ids)),
      );
      const unprocessableString = results.unprocessableReferences.join(' ');
      this.inputValue = unprocessableString;
    },
    processIssuableReferences(rawReferences) {
      const references = rawReferences
        .filter(reference => this.checkIsProcessable(reference));

      const unprocessableReferences = rawReferences
        .filter(reference => !this.checkIsProcessable(reference));

      // Add some temporary placeholders to lookup while we wait
      // for data to come back from the server
      const ids = references.map((reference) => {
        const issueEntry = this.state.issueMap[reference];
        const id = issueEntry ? issueEntry.id : `pending_${reference}`;
        const isIssueErrored = issueEntry &&
          issueEntry.fetchStatus === FETCH_ERROR_STATUS;

        if (!issueEntry || isIssueErrored) {
          this.store.addToIssueMap(id, {
            id,
            reference,
            fetchStatus: FETCHING_STATUS,
          });

          // TODO: We will only need to pass in the references once `3` is in place, https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1797#todo
          this.service.fetchIssueFromReference(
            reference,
            this.currentNamespacePath,
            this.currentProjectPath,
          )
            .then((issue) => {
              // They may have input a valid looking reference but it doesn't actually exist
              // Or they don't have the permissions to relate it.
              if (issue) {
                // Add our fully-qualified entry
                this.store.addToIssueMap(issue.id, {
                  ...issue,
                  fetchStatus: FETCH_SUCCESS_STATUS,
                });

                // Update our reference lists to point to the
                // fully-qualified entry in the issueMap
                this.store.setPendingRelatedIssues(
                  _.uniq(this.replaceInList(
                    this.state.pendingRelatedIssues,
                    id,
                    issue.id,
                  )),
                );
              } else {
                // Mark the issue as trouble-some
                this.store.addToIssueMap(id, {
                  ...this.store.getIssue(id),
                  fetchStatus: FETCH_ERROR_STATUS,
                });
              }
            })
            .catch(() => new Flash('An error occurred while fetching issue info.'));
        }

        return id;
      });

      return {
        unprocessableReferences,
        references,
        ids,
      };
    },

    replaceInList(list, needle, replacement) {
      return list.map((item) => {
        if (item === needle) {
          return replacement;
        }

        return item;
      });
    },
    checkIsProcessable(reference) {
      const isValidReference = ISSUABLE_REFERENCE_REGEX.test(reference);
      const isRoughIssueUrl = ISSUABLE_URL_REGEX.test(reference);
      const isProcessable = isValidReference || isRoughIssueUrl;

      return isProcessable;
    },
  },

  created() {
    eventHub.$on('relatedIssue-removeRequest', this.onRelatedIssueRemoveRequest);
    eventHub.$on('showAddRelatedIssuesForm', this.onShowAddRelatedIssuesForm);
    eventHub.$on('pendingIssuable-removeRequest', this.onAddIssuableFormIssuableRemoveRequest);
    eventHub.$on('addIssuableFormSubmit', this.onAddIssuableFormSubmit);
    eventHub.$on('addIssuableFormCancel', this.onAddIssuableFormCancel);
    eventHub.$on('addIssuableFormInput', this.onAddIssuableFormInput);
    eventHub.$on('addIssuableFormBlur', this.onAddIssuableFormBlur);

    this.service = new RelatedIssuesService(this.endpoint);
    this.fetchRelatedIssues();
  },

  beforeDestroy() {
    eventHub.$off('relatedIssue-removeRequest', this.onRelatedIssueRemoveRequest);
    eventHub.$off('showAddRelatedIssuesForm', this.onShowAddRelatedIssuesForm);
    eventHub.$off('pendingIssuable-removeRequest', this.onAddIssuableFormIssuableRemoveRequest);
    eventHub.$off('addIssuableFormSubmit', this.onAddIssuableFormSubmit);
    eventHub.$off('addIssuableFormCancel', this.onAddIssuableFormCancel);
    eventHub.$off('addIssuableFormInput', this.onAddIssuableFormInput);
    eventHub.$off('addIssuableFormBlur', this.onAddIssuableFormBlur);
  },
};
</script>

<template>
  <related-issues-block
    :help-path="helpPath"
    :related-issues="computedRelatedIssues"
    :can-add-related-issues="canAddRelatedIssues"
    :pending-related-issues="computedPendingRelatedIssues"
    :is-form-visible="isFormVisible"
    :input-value="inputValue"
    :auto-complete-sources="autoCompleteSources" />
</template>
