import eventHub from '../../../event_hub';
import CESquashBeforeMerge from '../../../components/states/mr_widget_squash_before_merge';

export default {
  extends: CESquashBeforeMerge,
  inherits: true,
  props: {
    isMergeButtonDisabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      squashBeforeMerge: false,
    };
  },
  methods: {
    updateSquashModel() {
      eventHub.$emit('MRWidgetUpdateSquash', this.squashBeforeMerge);
    },
  },
  template: `
    <div class="accept-control spacing inline">
      <label class="merge-param-checkbox">
        <input 
          type="checkbox"
          :disabled="isMergeButtonDisabled"
          v-model="squashBeforeMerge"
          @change="updateSquashModel"/>
        Squash commits
      </label>
      <a title data-title="About this feature" data-toggle="tooltip" data-placement="bottom" data-container="body" href="/help/user/project/merge_requests/squash_and_merge">
        <i class="fa fa-question-circle"></i>
      </a>
    </div>`,
};
