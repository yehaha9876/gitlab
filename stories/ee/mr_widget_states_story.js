import { storiesOf } from '@storybook/vue';
import { addonKnobs } from '@storybook/addon-knobs';
import GeoSecondaryNode from '../../app/assets/javascripts/vue_merge_request_widget/ee/components/states/mr_widget_secondary_geo_node';
import RebaseState from '../../app/assets/javascripts/vue_merge_request_widget/ee/components/states/mr_widget_rebase';

function makeStory({ component, props }) {
  return addonKnobs()(() => ({
    data() {
      return {
        service: {},
        component,
      };
    },
    computed: {
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

const props = {
  state: 'opened',
  targetBranch: 'foo',
  shouldBeRebased: true,
  rebasePath: true,
};

const rebaseStories = storiesOf('MR Widget EE.States.Rebase', module);
rebaseStories.add('Can rebase', makeStory({
  component: RebaseState,
  props: {
    ...props,
    canPushToSourceBranch: true,
  },
}));

rebaseStories.add('Cannot rebase', makeStory({
  component: RebaseState,
  props: {
    ...props,
    canPushToSourceBranch: false,
  },
}));

rebaseStories.add('In progress', makeStory({
  component: RebaseState,
  props: {
    ...props,
    rebaseInProgress: true,
  },
}));

const geoStories = storiesOf('MR Widget EE.States.Secondary Geo Node', module);

geoStories.add('Geo Secondary Node', makeStory({
  component: GeoSecondaryNode,
  props: {
    isGeoSecondaryNode: true,
  },
}));

export default {
  geoStories,
  rebaseStories,
};
