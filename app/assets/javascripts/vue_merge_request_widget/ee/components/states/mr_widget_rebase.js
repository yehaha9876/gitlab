/* global Flash */

import simplePoll from '~/lib/utils/simple_poll';
import eventHub from '../../../event_hub';
import statusIcon from '../../../components/mr_widget_status_icon';

export default {
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  components: {
    statusIcon,
  },
  data() {
    return {
      isMakingRequest: false,
    };
  },
  computed: {
    status() {
      if (!this.mr.canPushToSourceBranch && !this.mr.rebaseInProgress) {
        return 'failed';
      }
      return 'success';
    },
  },
  methods: {
    rebase() {
      this.isMakingRequest = true;
      this.service.rebase().then(() => {
        simplePoll((continuePolling, stopPolling) => {
          this.service.poll()
            .then(res => res.json())
            .then((res) => {
              if (res.rebase_in_progress) {
                continuePolling();
              } else {
                this.isMakingRequest = false;
                eventHub.$emit('MRWidgetUpdateRequested');
                stopPolling();
              }
            })
            .catch(() => {
              this.isMakingRequest = false;
              new Flash('Something went wrong. Please try again.'); // eslint-disable-line
              stopPolling();
            });
        });
      }).catch(() => {
        this.isMakingRequest = false;
        new Flash('Something went wrong. Please try again.'); // eslint-disable-line
      });
    },
  },
  template: `
    <div class="mr-widget-body media">
      <div v-if="mr.rebaseInProgress || isMakingRequest" class="mr-widget-icon">
        <i
          class="fa fa-spinner fa-spin"
          aria-hidden="true" />
      </div>
      <status-icon v-else :status="status" />
      <div class="rebase-state-find-class-convention media-body space-children">
        <template v-if="mr.rebaseInProgress || isMakingRequest">
          <button
            type="button"
            class="btn btn-success btn-small"
            disabled="true">
            Merge
          </button>
          <span class="bold">
            Rebase in progress
          </span>
        </template>
        <template v-if="!mr.rebaseInProgress && !mr.canPushToSourceBranch">
          <button
            type="button"
            class="btn btn-success btn-small"
            disabled="true">
            Merge
          </button>
          <span class="bold">
            Fast-forward merge is not possible.
            Rebase the source branch onto
            <span class="label-branch">{{mr.targetBranch}}</span>
            to allow this merge request to be merged
          </span>
        </template>
        <template v-if="!mr.rebaseInProgress && mr.canPushToSourceBranch && !isMakingRequest">
          <div class="accept-merge-holder clearfix js-toggle-container accept-action space-children">
            <button
              class="btn btn-small btn-reopen btn-success"
              :disabled="isMakingRequest"
              @click="rebase">
              <i
                v-if="isMakingRequest"
                class="fa fa-spinner fa-spin"
                aria-hidden="true" />
              Rebase
            </button>
            <span class="bold">
              Fast-forward merge is not possible.
              Rebase the source branch onto the target branch or merge target
              branch into source branch to allow this merge request to be merged
            </span>
          </div>
        </template>
      </div>
    </div>
  `,
};
