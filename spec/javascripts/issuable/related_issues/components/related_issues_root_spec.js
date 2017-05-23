import Vue from 'vue';
import RelatedIssuesRoot from '~/issuable/related_issues/components/related_issues_root.vue';
import { FETCH_SUCCESS_STATUS } from '~/issuable/related_issues/constants';

const defaultProps = {
  endpoint: '/foo/bar/issues/1/related_issues',
  currentNamespacePath: 'foo',
  currentProjectPath: 'bar',
};

const createComponent = (propsData = {}) => {
  const Component = Vue.extend(RelatedIssuesRoot);

  return new Component({
    propsData,
  })
    .$mount();
};

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

describe('RelatedIssuesRoot', () => {
  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('methods', () => {
    describe('onRelatedIssueRemoveRequest', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
        vm.store.addToIssueMap(issuable1Reference, issuable1);
        vm.store.setRelatedIssues([issuable1Reference]);
      });

      it('remove related issue and succeeds', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 200,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.onRelatedIssueRemoveRequest(issuable1Reference);

        setTimeout(() => {
          expect(vm.computedRelatedIssues).toEqual([]);

          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

          done();
        });
      });

      it('remove related issue, fails, and restores to related issues', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 422,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.onRelatedIssueRemoveRequest(issuable1Reference);

        setTimeout(() => {
          expect(vm.computedRelatedIssues.length).toEqual(1);
          expect(vm.computedRelatedIssues[0].reference).toEqual(issuable1Reference);

          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

          done();
        });
      });
    });

    describe('onShowAddRelatedIssuesForm', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
      });

      it('show add related issues form', () => {
        vm.onShowAddRelatedIssuesForm();

        expect(vm.isFormVisible).toEqual(true);
      });
    });

    describe('onAddIssuableFormIssuableRemoveRequest', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
        vm.store.addToIssueMap(issuable1Reference, issuable1);
        vm.store.setPendingRelatedIssues([issuable1Reference]);
      });

      it('remove pending related issue', () => {
        vm.onAddIssuableFormIssuableRemoveRequest(issuable1Reference);

        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
      });
    });

    describe('onAddIssuableFormSubmit', () => {
      const interceptor = (request, next) => {
        next(request.respondWith(JSON.stringify({}), {
          status: 200,
        }));
      };

      beforeEach(() => {
        vm = createComponent(defaultProps);
        vm.store.addToIssueMap(issuable1.id, issuable1);
        vm.store.addToIssueMap(issuable2.id, issuable2);

        Vue.http.interceptors.push(interceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
      });

      it('submit zero pending issue as related issue', (done) => {
        vm.store.setPendingRelatedIssues([]);
        vm.onAddIssuableFormSubmit();

        setTimeout(() => {
          expect(vm.computedPendingRelatedIssues.length).toEqual(0);
          expect(vm.computedRelatedIssues.length).toEqual(0);

          done();
        });
      });

      it('submit pending issue as related issue', (done) => {
        vm.store.setPendingRelatedIssues([issuable1.id]);
        vm.onAddIssuableFormSubmit();

        setTimeout(() => {
          console.log(vm.computedRelatedIssues[0]);
          expect(vm.computedPendingRelatedIssues.length).toEqual(0);
          expect(vm.computedRelatedIssues.length).toEqual(1);
          expect(vm.computedRelatedIssues[0].reference).toEqual(issuable1Reference);

          done();
        });
      });

      it('submit multiple pending issues as related issues', (done) => {
        vm.store.setPendingRelatedIssues([issuable1Reference, issuable2Reference]);
        vm.onAddIssuableFormSubmit();

        setTimeout(() => {
          expect(vm.computedPendingRelatedIssues.length).toEqual(0);
          expect(vm.computedRelatedIssues.length).toEqual(2);
          expect(vm.computedRelatedIssues[0].reference).toEqual(issuable1Reference);
          expect(vm.computedRelatedIssues[1].reference).toEqual(issuable2Reference);

          done();
        });
      });
    });

    describe('onAddIssuableFormCancel', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
        vm.isFormVisible = true;
        vm.inputValue = 'foo';
      });

      it('when canceling and hiding add issuable form', () => {
        vm.onAddIssuableFormCancel();

        expect(vm.isFormVisible).toEqual(false);
        expect(vm.inputValue).toEqual('');
        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
      });
    });

    describe('fetchRelatedIssues', () => {
      const interceptor = (request, next) => {
        next(request.respondWith(JSON.stringify([issuable1, issuable2]), {
          status: 200,
        }));
      };

      beforeEach(() => {
        vm = createComponent(defaultProps);

        Vue.http.interceptors.push(interceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
      });

      it('fetching related issues', (done) => {
        vm.fetchRelatedIssues();

        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.computedRelatedIssues.length).toEqual(2);
            expect(vm.computedRelatedIssues[0].reference).toEqual(issuable1Reference);
            expect(vm.computedRelatedIssues[1].reference).toEqual(issuable2Reference);

            done();
          });
        });
      });
    });

    describe('onAddIssuableFormInput', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
      });

      it('fill in issue number reference and adds to pending related issues', () => {
        const input = '#123 ';
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('#123');
      });

      it('fill in with full reference', () => {
        const input = 'asdf/qwer#444 ';
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('asdf/qwer#444');
      });

      it('fill in with multiple references', () => {
        const input = 'asdf/qwer#444 #12 ';
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(2);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('asdf/qwer#444');
        expect(vm.computedPendingRelatedIssues[1].reference).toEqual('#12');
      });

      it('fill in with some invalid things', () => {
        const input = 'something random stuff here ';
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
      });

      it('fill in invalid and some legit references', () => {
        const input = 'something random #123 ';
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('#123');
      });

      it('keep reference piece in input while we are touching it', () => {
        const input = 'a #123 b';
        vm.onAddIssuableFormInput(input, 3);

        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
      });
    });

    describe('onAddIssuableFormBlur', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
      });

      it('add valid reference to pending when blurring', () => {
        const input = '#123';
        vm.onAddIssuableFormBlur(input);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('#123');
      });

      it('add any valid references to pending when blurring', () => {
        const input = 'asdf #123';
        vm.onAddIssuableFormBlur(input);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('#123');
      });
    });

    describe('processIssuableReferences', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
      });

      it('process issue number reference', () => {
        const reference = '#123';
        const result = vm.processIssuableReferences([reference]);

        expect(result).toEqual({
          unprocessableReferences: [],
          references: [reference],
          ids: jasmine.any(Array),
        });
      });

      it('process multiple issue number references with some unprocecessable', () => {
        const rawReferences = '#123 abc #456'.split(/\s/);
        const result = vm.processIssuableReferences(rawReferences);

        expect(result).toEqual({
          unprocessableReferences: [
            'abc',
          ],
          references: [
            rawReferences[0],
            rawReferences[2],
          ],
          ids: jasmine.any(Array),
        });
      });
    });
  });
});
