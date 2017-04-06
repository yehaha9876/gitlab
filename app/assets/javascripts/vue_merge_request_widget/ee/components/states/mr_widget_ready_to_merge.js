import eventHub from '../../../event_hub';
import ReadyToMergeState from '../../../components/states/mr_widget_ready_to_merge';

export default {
  extends: ReadyToMergeState,
  name: 'MRWidgetReadyToMerge',
  data() {
    return {
      additionalParams: {
        squash: false,
      },
    };
  },
  methods: {
    // called in CE super component before form submission
    setAdditionalParams(options) {
      if (this.additionalParams) {
        Object.assign(options, this.additionalParams);
      }
    },
  },
  created() {
    eventHub.$on('MRWidgetUpdateSquash', (val) => {
      this.additionalParams.squash = val;
    });
  },
};
