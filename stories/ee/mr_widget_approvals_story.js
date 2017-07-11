import { storiesOf } from '@storybook/vue';
import { addonKnobs, boolean, select, text } from '@storybook/addon-knobs';
import MRWidgetApprovals from '../../app/assets/javascripts/vue_merge_request_widget/ee/components/approvals/mr_widget_approvals';
import MRWidgetStore from '../..//app/assets/javascripts/vue_merge_request_widget/ee/stores/mr_widget_store';
import mockData from '../../spec/javascripts/vue_mr_widget/mock_data';

window.gon = window.gon || {};
window.gon.current_user_id = 1;

const stories = storiesOf('MR Widget EE.Approvals', module);

function makeStory({ props, service = {} }) {
  return addonKnobs()(() => ({
    components: {
      'mr-widget-approvals': MRWidgetApprovals,
    },
    data() {
      return {
        service,
        mr: {
          ...props,
        },
      };
    },
    computed: {
      computedMr() {
        return new MRWidgetStore({
          ...this.mr,
          state: this.state,
        });
      },
    },
    template: `
      <div class="container-fluid container-limited limit-container-width">
        <div class="content" id="content-body">
          <div class="mr-state-widget prepend-top-default">
              <mr-widget-approvals
                :mr="computedMr"
                :service="service" />
          </div>
        </div>
      </div>
    `,
  }));
}

const props = {
  approvals_path: '/approve',
  current_user: {
    can_remove_source_branch: true,
    can_revert_on_current_merge_request: null,
    can_cherry_pick_on_current_merge_request: false,
  },
};

const approvals = {
  suggested_approvers: [{
    user: {
      weburl: 'http://foo.bar',
      avatarurl: 'http://gravatar.com/foo',
      name: 'fatihacet',
    },
  }],
  approved_by: [{
    user: {
      weburl: 'http://foo.bar',
      avatarurl: 'http://gravatar.com/foo',
      name: 'fatihacet',
    },
  }],
  approvals_left: 4,
};

const noopService = {
  fetchApprovals: () => Promise.resolve(),
};

function mockService(options) {
  return {
    fetchApprovals: () => Promise.resolve({
      ...approvals,
      ...options,
    }),
  };
}

stories.add('All required approvals', makeStory({
  props,
  service: mockService({
    approvals_left: 0,
  }),
}));

stories.add('Some approvals', makeStory({
  props,
  service: mockService({
    user_can_approve: true,
    user_has_approved: false,
  }),
}));

stories.add('My approval', makeStory({
  props,
  service: mockService({
    user_can_approve: false,
    user_has_approved: true,
    approvals_left: 0,
  }),
}));

stories.add('No approvals', makeStory({
  props,
  service: mockService({
    approved_by: [],
  }),
}));

stories.add('Loading', makeStory({
  props,
  service: noopService,
}));

export default stories;
