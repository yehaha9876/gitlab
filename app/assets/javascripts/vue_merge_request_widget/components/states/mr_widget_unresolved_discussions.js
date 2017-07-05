import ciIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  name: 'MRWidgetUnresolvedDiscussions',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    ciIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <ci-icon :status="{ group: 'failed', icon: 'icon_status_failed' }" />
      <div class="media-body">
        <span class="bold">
          There are unresolved discussions. Please resolve these discussions
        </span>
        <button
          type="button"
          class="btn btn-success btn-xs"
          disabled="true">
          Merge
        </button>
        <a
          v-if="mr.createIssueToResolveDiscussionsPath"
          :href="mr.createIssueToResolveDiscussionsPath"
          class="btn btn-default btn-xs js-create-issue">
          Create an issue to resolve them later
        </a>
      </div>
    </div>
  `,
};
