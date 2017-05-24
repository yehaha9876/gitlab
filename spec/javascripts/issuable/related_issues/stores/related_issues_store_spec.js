import _ from 'underscore';
import {
  FETCH_SUCCESS_STATUS,
  FETCH_ERROR_STATUS,
} from '~/issuable/related_issues/constants';
import RelatedIssuesStore from '~/issuable/related_issues/stores/related_issues_store';

const issuable1 = {
  namespace_full_path: 'foo',
  project_path: 'bar',
  id: '200',
  iid: '123',
  title: 'issue1',
  path: '/foo/bar/issues/123',
  state: 'opened',
  fetchStatus: FETCH_SUCCESS_STATUS,
  destroy_relation_path: '/foo/bar/issues/123/related_issues/1',
};
const issuable1Reference = `${issuable1.namespace_full_path}/${issuable1.project_path}#${issuable1.iid}`;

const issuable2 = {
  namespace_full_path: 'foo',
  project_path: 'bar',
  id: '201',
  iid: '124',
  title: 'issue1',
  path: '/foo/bar/issues/124',
  state: 'opened',
  fetchStatus: FETCH_SUCCESS_STATUS,
  destroy_relation_path: '/foo/bar/issues/124/related_issues/1',
};
const issuable2Reference = `${issuable2.namespace_full_path}/${issuable2.project_path}#${issuable2.iid}`;

describe('RelatedIssuesStore', () => {
  let store;

  beforeEach(() => {
    store = new RelatedIssuesStore();
  });

  describe('getIssue', () => {
    it('get issue with issueMap populated', () => {
      store.state.issueMap = {
        [issuable1.id]: issuable1,
      };
      expect(store.getIssue(issuable1.id, 'foo', 'bar')).toEqual({
        ..._.omit(issuable1, 'namespace_full_path', 'project_path', 'iid', 'destroy_relation_path'),
        reference: issuable1Reference,
        displayReference: '#123',
        fetchStatus: FETCH_SUCCESS_STATUS,
        canRemove: true,
      });
    });

    it('get issue with issue missing in issueMap', () => {
      expect(store.getIssue(issuable1.id, 'foo', 'bar')).toEqual({
        id: issuable1.id,
        reference: issuable1.id,
        displayReference: issuable1.id,
        title: undefined,
        path: undefined,
        state: undefined,
        fetchStatus: FETCH_ERROR_STATUS,
        canRemove: undefined,
      });
    });
  });

  describe('getIssues', () => {
    it('get issues with issueMap populated', () => {
      store.state.issueMap = {
        [issuable1.id]: issuable1,
        [issuable2.id]: issuable2,
      };
      expect(store.getIssues([issuable1.id, issuable2.id], 'foo', 'bar')).toEqual([{
        ..._.omit(issuable1, 'namespace_full_path', 'project_path', 'iid', 'destroy_relation_path'),
        reference: issuable1Reference,
        displayReference: '#123',
        fetchStatus: FETCH_SUCCESS_STATUS,
        canRemove: true,
      }, {
        ..._.omit(issuable2, 'namespace_full_path', 'project_path', 'iid', 'destroy_relation_path'),
        reference: issuable2Reference,
        displayReference: '#124',
        fetchStatus: FETCH_SUCCESS_STATUS,
        canRemove: true,
      }]);
    });
  });

  describe('addToIssueMap', () => {
    it('defaults to empty object hash', () => {
      expect(store.state.issueMap).toEqual({});
    });

    it('add issue', () => {
      store.addToIssueMap(issuable1.id, issuable1);

      expect(store.state.issueMap).toEqual({
        [issuable1.id]: issuable1,
      });
    });
  });

  describe('setRelatedIssues', () => {
    it('defaults to empty array', () => {
      expect(store.state.relatedIssues).toEqual([]);
    });

    it('add reference', () => {
      const relatedIssues = [issuable1.id];
      store.setRelatedIssues(relatedIssues);

      expect(store.state.relatedIssues).toEqual(relatedIssues);
    });
  });

  describe('removeRelatedIssue', () => {
    it('remove issue', () => {
      const relatedIssues = [issuable1.id];
      store.state.relatedIssues = relatedIssues;

      store.removeRelatedIssue(issuable1.id);

      expect(store.state.relatedIssues).toEqual([]);
    });

    it('remove issue with multiple in store', () => {
      const relatedIssues = [issuable1.id, issuable2.id];
      store.state.relatedIssues = relatedIssues;

      store.removeRelatedIssue(issuable1.id);

      expect(store.state.relatedIssues).toEqual([issuable2.id]);
    });
  });

  describe('setPendingRelatedIssues', () => {
    it('defaults to empty array', () => {
      expect(store.state.pendingRelatedIssues).toEqual([]);
    });

    it('add reference', () => {
      const relatedIssues = [issuable1.id];
      store.setPendingRelatedIssues(relatedIssues);

      expect(store.state.pendingRelatedIssues).toEqual(relatedIssues);
    });
  });

  describe('removePendingRelatedIssue', () => {
    it('remove issue', () => {
      const relatedIssues = [issuable1.id];
      store.state.pendingRelatedIssues = relatedIssues;

      store.removePendingRelatedIssue(issuable1.id);

      expect(store.state.pendingRelatedIssues).toEqual([]);
    });

    it('remove issue with multiple in store', () => {
      const relatedIssues = [issuable1.id, issuable2.id];
      store.state.pendingRelatedIssues = relatedIssues;

      store.removePendingRelatedIssue(issuable1.id);

      expect(store.state.pendingRelatedIssues).toEqual([issuable2.id]);
    });
  });
});
