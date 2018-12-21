import Vue from 'vue';
import mergedComponent from '~/vue_merge_request_widget/components/states/mr_widget_merged.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetMerged', () => {
  let vm;
  const targetBranch = 'foo';
  const selectors = {
    get copyMergeShaButton() {
      return vm.$el.querySelector('button.js-mr-merged-copy-sha');
    },
    get mergeCommitShaLink() {
      return vm.$el.querySelector('a.js-mr-merged-commit-sha');
    },
  };

  beforeEach(() => {
    const Component = Vue.extend(mergedComponent);
    const mr = {
      isDeletingSourceBranch: false,
      cherryPickInForkPath: false,
      canCherryPickInCurrentMR: true,
      revertInForkPath: false,
      canRevertInCurrentMR: true,
      canDeleteSourceBranch: true,
      sourceBranchDeleted: true,
      metrics: {
        mergedBy: {
          name: 'Administrator',
          username: 'root',
          webUrl: 'http://localhost:3000/root',
          avatarUrl:
            'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        },
        mergedAt: 'Jan 24, 2018 1:02pm GMT+0000',
        readableMergedAt: '',
        closedBy: {},
        closedAt: 'Jan 24, 2018 1:02pm GMT+0000',
        readableClosedAt: '',
      },
      updatedAt: 'mergedUpdatedAt',
      shortMergeCommitSha: '958c0475',
      mergeCommitSha: '958c047516e182dfc52317f721f696e8a1ee85ed',
      mergeCommitPath:
        'http://localhost:3000/root/nautilus/commit/f7ce827c314c9340b075657fd61c789fb01cf74d',
      sourceBranch: 'bar',
      targetBranch,
    };

    const service = {
      deleteSourceBranch() {},
    };

    spyOn(eventHub, '$emit');

    vm = mountComponent(Component, { mr, service });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('shouldShowDeleteSourceBranch', () => {
      it('returns true when sourceBranchDeleted is false', () => {
        vm.mr.sourceBranchDeleted = false;

        expect(vm.shouldShowDeleteSourceBranch).toEqual(true);
      });

      it('returns false when sourceBranchDeleted is true', () => {
        vm.mr.sourceBranchDeleted = true;

        expect(vm.shouldShowDeleteSourceBranch).toEqual(false);
      });

      it('returns false when canDeleteSourceBranch is false', () => {
        vm.mr.sourceBranchDeleted = false;
        vm.mr.canDeleteSourceBranch = false;

        expect(vm.shouldShowDeleteSourceBranch).toEqual(false);
      });

      it('returns false when is making request', () => {
        vm.mr.canDeleteSourceBranch = true;
        vm.isMakingRequest = true;

        expect(vm.shouldShowDeleteSourceBranch).toEqual(false);
      });

      it('returns true when all are true', () => {
        vm.mr.isDeletingSourceBranch = true;
        vm.mr.canDeleteSourceBranch = true;
        vm.isMakingRequest = true;

        expect(vm.shouldShowDeleteSourceBranch).toEqual(false);
      });
    });

    describe('shouldShowSourceBranchDeleting', () => {
      it('should correct value when fields changed', () => {
        vm.mr.sourceBranchDeleted = false;

        expect(vm.shouldShowSourceBranchDeleting).toEqual(false);

        vm.mr.sourceBranchDeleted = true;

        expect(vm.shouldShowDeleteSourceBranch).toEqual(false);

        vm.mr.sourceBranchDeleted = false;
        vm.isMakingRequest = true;

        expect(vm.shouldShowSourceBranchDeleting).toEqual(true);

        vm.isMakingRequest = false;
        vm.mr.isDeletingSourceBranch = true;

        expect(vm.shouldShowSourceBranchDeleting).toEqual(true);
      });
    });
  });

  describe('methods', () => {
    describe('deleteSourceBranch', () => {
      it('should set flag and call service then request main component to update the widget', done => {
        spyOn(vm.service, 'deleteSourceBranch').and.returnValue(
          new Promise(resolve => {
            resolve({
              data: {
                message: 'Branch was deleted',
              },
            });
          }),
        );

        vm.deleteSourceBranch();
        setTimeout(() => {
          const args = eventHub.$emit.calls.argsFor(0);

          expect(vm.isMakingRequest).toEqual(true);
          expect(args[0]).toEqual('MRWidgetUpdateRequested');
          expect(args[1]).not.toThrow();
          done();
        }, 333);
      });
    });
  });

  it('has merged by information', () => {
    expect(vm.$el.textContent).toContain('Merged by');
    expect(vm.$el.textContent).toContain('Administrator');
  });

  it('renders branch information', () => {
    expect(vm.$el.textContent).toContain('The changes were merged into');
    expect(vm.$el.textContent).toContain(targetBranch);
  });

  it('renders information about branch being deleted', () => {
    expect(vm.$el.textContent).toContain('The source branch has been deleted');
  });

  it('shows revert and cherry-pick buttons', () => {
    expect(vm.$el.textContent).toContain('Revert');
    expect(vm.$el.textContent).toContain('Cherry-pick');
  });

  it('shows button to copy commit SHA to clipboard', () => {
    expect(selectors.copyMergeShaButton).toExist();
    expect(selectors.copyMergeShaButton.getAttribute('data-clipboard-text')).toBe(
      vm.mr.mergeCommitSha,
    );
  });

  it('hides button to copy commit SHA if SHA does not exist', done => {
    vm.mr.mergeCommitSha = null;

    Vue.nextTick(() => {
      expect(selectors.copyMergeShaButton).not.toExist();
      expect(vm.$el.querySelector('.mr-info-list').innerText).not.toContain('with');
      done();
    });
  });

  it('shows merge commit SHA link', () => {
    expect(selectors.mergeCommitShaLink).toExist();
    expect(selectors.mergeCommitShaLink.text).toContain(vm.mr.shortMergeCommitSha);
    expect(selectors.mergeCommitShaLink.href).toBe(vm.mr.mergeCommitPath);
  });

  it('should not show source branch deleted text', done => {
    vm.mr.sourceBranchDeleted = false;

    Vue.nextTick(() => {
      expect(vm.$el.innerText).toContain('You can delete source branch now');
      expect(vm.$el.innerText).not.toContain('The source branch has been deleted');
      done();
    });
  });

  it('should show source branch deleting text', done => {
    vm.mr.isDeletingSourceBranch = true;
    vm.mr.sourceBranchDeleted = false;

    Vue.nextTick(() => {
      expect(vm.$el.innerText).toContain('The source branch is being deleted');
      expect(vm.$el.innerText).not.toContain('You can delete source branch now');
      expect(vm.$el.innerText).not.toContain('The source branch has been deleted');
      done();
    });
  });

  it('should use mergedEvent mergedAt as tooltip title', () => {
    expect(vm.$el.querySelector('time').getAttribute('data-original-title')).toBe(
      'Jan 24, 2018 1:02pm GMT+0000',
    );
  });
});
