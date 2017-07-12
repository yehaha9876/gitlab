import { storiesOf } from '@storybook/vue';
import { addonKnobs, boolean, select, text } from '@storybook/addon-knobs';
import * as mrWidget from '../app/assets/javascripts/vue_merge_request_widget/dependencies';
import mockData from '../spec/javascripts/vue_mr_widget/mock_data';

// gl global stuff that isn't imported
import '../app/assets/javascripts/lib/utils/datetime_utility';
import '../app/assets/javascripts/lib/utils/common_utils';
import '../app/assets/javascripts/commons/bootstrap';
import '../app/assets/javascripts/flash';

window.gon = window.gon || {};
window.gon.current_user_id = 1;

const stories = storiesOf('MR Widget States', module);

function makeStory({ component, props }) {
  return addonKnobs()(() => ({
    components: mrWidget,
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

const mergedProps = {
  state: 'merged',
  isRemovingSourceBranch: false,
  cherryPickInForkPath: false,
  canCherryPickInCurrentMR: true,
  revertInForkPath: false,
  canRevertInCurrentMR: true,
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

stories.add('Merged', makeStory({
  component: mrWidget.MergedState,
  props: mergedProps,
}));

const lockedProps = {
  state: 'locked',
  targetBranchPath: '/branch-path',
  targetBranch: 'branch',
};

stories.add('Locked', makeStory({
  component: mrWidget.LockedState,
  props: lockedProps,
}));

export default stories;
