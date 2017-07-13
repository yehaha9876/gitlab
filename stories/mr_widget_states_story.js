import { storiesOf } from '@storybook/vue';
import { addonKnobs, boolean, select, text } from '@storybook/addon-knobs';
import * as mrWidget from '../app/assets/javascripts/vue_merge_request_widget/dependencies';
import mockData from '../spec/javascripts/vue_mr_widget/mock_data';
import {
  WidgetHeader,
  WidgetMergeHelp,
  WidgetPipeline,
  WidgetDeployment,
  WidgetRelatedLinks,
  MergedState,
  ClosedState,
  LockedState,
  WipState,
  ArchivedState,
  ConflictsState,
  NothingToMergeState,
  MissingBranchState,
  NotAllowedState,
  ReadyToMergeState,
  SHAMismatchState,
  UnresolvedDiscussionsState,
  PipelineBlockedState,
  PipelineFailedState,
  FailedToMerge,
  MergeWhenPipelineSucceedsState,
  AutoMergeFailed,
  CheckingState,
  MRWidgetStore,
  MRWidgetService,
  eventHub,
  stateMaps,
  SquashBeforeMerge,
  notify,
} from '../app/assets/javascripts/vue_merge_request_widget/dependencies';

window.gon = window.gon || {};
window.gon.current_user_id = 1;

const stories = storiesOf('MR Widget.States', module);

function makeStory({ component, props }) {
  return addonKnobs()(() => ({
    components: {
      ...mrWidget,
      'mr-widget-header': WidgetHeader,
      'mr-widget-merge-help': WidgetMergeHelp,
      'mr-widget-pipeline': WidgetPipeline,
      'mr-widget-deployment': WidgetDeployment,
      'mr-widget-related-links': WidgetRelatedLinks,
      'mr-widget-merged': MergedState,
      'mr-widget-closed': ClosedState,
      'mr-widget-locked': LockedState,
      'mr-widget-failed-to-merge': FailedToMerge,
      'mr-widget-wip': WipState,
      'mr-widget-archived': ArchivedState,
      'mr-widget-conflicts': ConflictsState,
      'mr-widget-nothing-to-merge': NothingToMergeState,
      'mr-widget-not-allowed': NotAllowedState,
      'mr-widget-missing-branch': MissingBranchState,
      'mr-widget-ready-to-merge': ReadyToMergeState,
      'mr-widget-sha-mismatch': SHAMismatchState,
      'mr-widget-squash-before-merge': SquashBeforeMerge,
      'mr-widget-checking': CheckingState,
      'mr-widget-unresolved-discussions': UnresolvedDiscussionsState,
      'mr-widget-pipeline-blocked': PipelineBlockedState,
      'mr-widget-pipeline-failed': PipelineFailedState,
      'mr-widget-merge-when-pipeline-succeeds': MergeWhenPipelineSucceedsState,
      'mr-widget-auto-merge-failed': AutoMergeFailed,

    },
    data() {
      return {
        service: {},
        component,
      };
    },
    computed: {
      componentName() {
        return mrWidget.stateMaps.stateToComponentMap[this.mr.state];
      },
      mr() {
        return {
          ...props,
          state: this.state,
        };
      },
    },
    template: `
      <div class="container-fluid container-limited limit-container-width">
        <div class="content" id="content-body">
          <div class="mr-state-widget prepend-top-default">
            <div class="mr-widget-section">
              <component
                :is="component"
                :mr="mr"
                :service="service" />
            </div>
          </div>
        </div>
      </div>
    `,
  }));
}

function makeStories(storyTitle, component, sections) {
  stories.add(storyTitle, () => ({
    data() {
      return {
        service: {},
        component,
      };
    },
    computed: {
      sections() {
        return sections.map(section => ({
          ...section,
          props: section.props || {},
        }));
      },
    },
    template: `
      <div class="container-fluid container-limited limit-container-width">
        <div class="content" id="content-body">
          <template v-for="section in sections">
            <h3>{{section.title}}</h3>
              <div class="mr-state-widget prepend-top-default">
                <div class="mr-widget-section">
                  <component
                    :is="component"
                    :mr="section.props"
                    :service="service" />
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>
    `,
  }));
}

const mergedProps = {
  state: 'merged',
  isRemovingSourceBranch: false,
  canRemoveSourceBranch: true,
  sourceBranchRemoved: true,
  updatedAt: '',
  targetBranch: 'foo',
  mergedAt: 'some time ago',
  mergedBy: {
    webUrl: 'http://foo.bar',
    avatarUrl: 'http://gravatar.com/foo',
    name: 'fatihacet',
  },
};

makeStories('Merged', mrWidget.MergedState, [
  {
    title: 'can remove source branch',
    props: {
      ...mergedProps,
      canRevertInCurrentMR: true,
      canCherryPickInCurrentMR: true,
      canRemoveSourceBranch: true,
      sourceBranchRemoved: false,
    },
  },
  {
    title: 'can revert',
    props: {
      ...mergedProps,
      canRevertInCurrentMR: true,
      canCherryPickInCurrentMR: true,
    },
  },
  {
    title: 'can revert in fork',
    props: {
      ...mergedProps,
      revertInForkPath: 'revert',
      cherryPickInForkPath: 'revert',
    },
  },
  {
    title: 'can cherry-pick',
    props: {
      ...mergedProps,
      canCherryPickInCurrentMR: true,
    },
  },
  {
    title: 'can cherry-pick in fork',
    props: {
      ...mergedProps,
      cherryPickInForkPath: 'revert',
    },
  },
  {
    title: 'removing branch',
    props: {
      ...mergedProps,
      canRevertInCurrentMR: true,
      canCerryPickInCurrentMR: true,
      sourceBranchRemoved: false,
      isRemovingSourceBranch: true,
    },
  },
]);

const lockedProps = {
  state: 'locked',
  targetBranchPath: '/branch-path',
  targetBranch: 'branch',
};

stories.add('Locked', makeStory({
  component: mrWidget.LockedState,
  props: lockedProps,
}));

stories.add('Conflicts', makeStory({
  component: mrWidget.ConflictsState,
  props: {
    canMerge: true,
    conflictResolutionPath: '/conflicts',
  },
}));

makeStories('Unresolved Discussions', mrWidget.UnresolvedDiscussionsState, [
  {
    title: 'can create issue',
    props: {
      createIssueToResolveDiscussionsPath: '/conflicts',
    },
  },
  {
    title: 'cannot create issue',
  },
]);

const allStates = mrWidget.stateMaps.stateToComponentMap;
Object.keys(allStates).forEach(state => {
  stories.add(state, makeStory({
    component: allStates[state],
    props: lockedProps,
  }));
});

export default stories;
