import ciIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  name: 'MRWidgetConflicts',
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
          There are merge conflicts.
          <span v-if="!mr.canMerge">
            Resolve these conflicts or ask someone with write access to this repository to merge it locally.
          </span>
        </span>
        <div
          v-if="mr.canMerge"
          class="btn-group">
          <a
            v-if="mr.conflictResolutionPath"
            :href="mr.conflictResolutionPath"
            class="btn btn-default btn-xs js-resolve-conflicts-button">
            Resolve conflicts
          </a>
          <button
            type="button"
            class="btn btn-success btn-xs"
            disabled="true">
            Merge
          </button>
          <a
            v-if="mr.canMerge"
            class="btn btn-default btn-xs js-merge-locally-button"
            data-toggle="modal"
            href="#modal_merge_info">
            Merge locally
          </a>
        </div>
      </div>
    </div>
  `,
};
