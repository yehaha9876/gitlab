<script>
  import axios from '~/lib/utils/axios_utils';
  import createFlash from '~/flash';
  import { saveFlashMessage } from '~/lib/utils/flash_queue';
  import GlModal from '~/vue_shared/components/gl_modal.vue';
  import { redirectTo } from '~/lib/utils/url_utility';
  import { s__, sprintf } from '~/locale';
  import eventHub from '../event_hub';

  export default {
    components: {
      GlModal,
    },
    props: {
      milestoneTitle: {
        type: String,
        required: true,
      },
      milestoneGroup: {
        type: String,
        required: true,
      },
      url: {
        type: String,
        required: true,
      },
    },
    computed: {
      title() {
        return sprintf(s__('Milestones|Promote %{title} to group milestone?'), { title: this.milestoneTitle });
      },
      text() {
        return sprintf(s__(
          `Milestones|<p>Promoting %{milestone} will make it available for all projects inside %{group}.
          Existing project milestones with the same name will be merged. </p>
          <p>Group milestones are currently %{missingFeature}. 
          You will not have these features once you've promoted a project milestone.
          They will be available in future releases.</p> This action cannot be reversed.`), {
            milestone: this.milestoneTitle,
            group: this.milestoneGroup,
            missingFeature: `<a href="https://docs.gitlab.com/ee/user/project/milestones/"
              target="_blank" rel="noopener noreferrer">
              missing features such as burndown charts
            </a>`,
          }, false);
      },
    },
    methods: {
      onSubmit() {
        eventHub.$emit('promoteMilestoneModal.requestStarted', this.url);
        return axios.post(this.url)
          .then((response) => {
            eventHub.$emit('promoteMilestoneModal.requestFinished', { milestoneUrl: this.url, successful: true });
            const responseURL = new URL(response.request.responseURL);
            const bodyData = responseURL.searchParams.get('body_data');
            saveFlashMessage(bodyData, `${this.milestoneTitle} promoted to group milestone`, 'notice');
            redirectTo(`${responseURL.protocol}//${responseURL.host}${responseURL.pathname}`);
          })
          .catch((error) => {
            eventHub.$emit('promoteMilestoneModal.requestFinished', { milestoneUrl: this.url, successful: false });
            createFlash(error);
          });
      },
    },
  };
</script>
<template>
  <gl-modal
    id="promote-milestone-modal"
    footer-primary-button-variant="warning"
    :footer-primary-button-text="s__('Milestones|Promote Milestone')"
    @submit="onSubmit"
  >
    <div
      slot="title"
    >
      {{ title }}
    </div>
    <div
      v-html="text"
    >
    </div>
  </gl-modal>
</template>

