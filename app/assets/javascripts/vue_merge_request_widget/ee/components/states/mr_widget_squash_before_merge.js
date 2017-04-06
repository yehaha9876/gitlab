import eventHub from '../../../event_hub';
import CESquashBeforeMerge from '../../../components/states/mr_widget_squash_before_merge';

export default {
  extends: CESquashBeforeMerge,
  props: {
    mr: {
      type: Object,
      required: true,
    },
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
      <a title data-title="About this feature" data-toggle="tooltip" data-placement="bottom" data-container="body" href="mr.squashBeforeMergeHelpPath">
        <i class="fa fa-question-circle" aria-hidden="true"></i>
      </a>
    </div>`,
};