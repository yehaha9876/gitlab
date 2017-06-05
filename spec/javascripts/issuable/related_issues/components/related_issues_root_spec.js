import Vue from 'vue';
import relatedIssuesRoot from '~/issuable/related_issues/components/related_issues_root.vue';
import { FETCH_SUCCESS_STATUS } from '~/issuable/related_issues/constants';

const defaultProps = {
  endpoint: '/foo/bar/issues/1/related_issues',
  currentNamespacePath: 'foo',
  currentProjectPath: 'bar',
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

describe('RelatedIssuesRoot', () => {
  let RelatedIssuesRoot;
  let vm;

  beforeEach(() => {
    RelatedIssuesRoot = Vue.extend(relatedIssuesRoot);
  });

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('methods', () => {
    describe('onRelatedIssueRemoveRequest', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
        vm.store.addToIssueMap(issuable1.id, issuable1);
        vm.store.setRelatedIssues([issuable1.id]);
      });

      it('remove related issue and succeeds', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({
            issues: [],
          }), {
            status: 200,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.onRelatedIssueRemoveRequest(issuable1.id);

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

        vm.onRelatedIssueRemoveRequest(issuable1.id);

        setTimeout(() => {
          expect(vm.computedRelatedIssues.length).toEqual(1);
          expect(vm.computedRelatedIssues[0].id).toEqual(issuable1.id);

          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

          done();
        });
      });
    });

    describe('onShowAddRelatedIssuesForm', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
      });

      it('show add related issues form', () => {
        vm.onShowAddRelatedIssuesForm();

        expect(vm.isFormVisible).toEqual(true);
      });
    });

    describe('onAddIssuableFormIssuableRemoveRequest', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
        vm.store.addToIssueMap(issuable1.id, issuable1);
        vm.store.setPendingRelatedIssues([issuable1.id]);
      });

      it('remove pending related issue', () => {
        vm.onAddIssuableFormIssuableRemoveRequest(issuable1.id);

        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
      });
    });

    describe('onAddIssuableFormSubmit', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
        vm.store.addToIssueMap(issuable1.id, issuable1);
        vm.store.addToIssueMap(issuable2.id, issuable2);
      });

      it('submit zero pending issue as related issue', (done) => {
        vm.store.setPendingRelatedIssues([]);
        vm.onAddIssuableFormSubmit();

        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.computedPendingRelatedIssues.length).toEqual(0);
            expect(vm.computedRelatedIssues.length).toEqual(0);

            done();
          });
        });
      });

      it('submit pending issue as related issue', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({
            issues: [issuable1],
            result: {
              message: 'something was successfully related',
              status: 'success',
            },
          }), {
            status: 200,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.store.setPendingRelatedIssues([issuable1.id]);
        vm.onAddIssuableFormSubmit();

        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.computedPendingRelatedIssues.length).toEqual(0);
            expect(vm.computedRelatedIssues.length).toEqual(1);
            expect(vm.computedRelatedIssues[0].id).toEqual(issuable1.id);

            done();

            Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
          });
        });
      });

      it('submit multiple pending issues as related issues', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({
            issues: [issuable1, issuable2],
            result: {
              message: 'something was successfully related',
              status: 'success',
            },
          }), {
            status: 200,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.store.setPendingRelatedIssues([issuable1.id, issuable2.id]);
        vm.onAddIssuableFormSubmit();

        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.computedPendingRelatedIssues.length).toEqual(0);
            expect(vm.computedRelatedIssues.length).toEqual(2);
            expect(vm.computedRelatedIssues[0].id).toEqual(issuable1.id);
            expect(vm.computedRelatedIssues[1].id).toEqual(issuable2.id);

            done();

            Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
          });
        });
      });
    });

    describe('onAddIssuableFormCancel', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
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
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();

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
            expect(vm.computedRelatedIssues[0].id).toEqual(issuable1.id);
            expect(vm.computedRelatedIssues[1].id).toEqual(issuable2.id);

            done();
          });
        });
      });
    });

    describe('onAddIssuableFormInput', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
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

      it('fill in with issue link', () => {
        const link = 'http://localhost:3000/foo/bar/issues/111';
        const input = `${link} `;
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual(link);
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
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
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
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
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
