/* global Flash */
import ciIcon from '../../../vue_shared/components/ci_icon.vue';
import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetWIP',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  data() {
    return {
      isMakingRequest: false,
    };
  },
  methods: {
    removeWIP() {
      this.isMakingRequest = true;
      this.service.removeWIP()
        .then(res => res.json())
        .then((res) => {
          eventHub.$emit('UpdateWidgetData', res);
          new Flash('The merge request can now be merged.', 'notice'); // eslint-disable-line
          $('.merge-request .detail-page-description .title').text(this.mr.title);
        })
        .catch(() => {
          this.isMakingRequest = false;
          new Flash('Something went wrong. Please try again.'); // eslint-disable-line
        });
    },
  },
  components: {
    ciIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <ci-icon :status="{ group: 'failed', icon: 'icon_status_failed' }" />
      <div class="media-body">
        <span class="bold">
          This is a Work in Progress
        </span>
        <template v-if="mr.removeWIPPath">
          <i
            class="fa fa-question-circle has-tooltip"
            title="When this merge request is ready, remove the WIP: prefix from the title to allow it to be merged." />
          <button
            type="button"
            class="btn btn-success btn-xs"
            disabled="true">
            Merge</button>
          <button
            @click="removeWIP"
            :disabled="isMakingRequest"
            type="button"
            class="btn btn-default btn-xs js-remove-wip">
            <i
              v-if="isMakingRequest"
              class="fa fa-spinner fa-spin"
              aria-hidden="true" />
              Resolve WIP status
          </button>
        </template>
      </div>
    </div>
  `,
};
