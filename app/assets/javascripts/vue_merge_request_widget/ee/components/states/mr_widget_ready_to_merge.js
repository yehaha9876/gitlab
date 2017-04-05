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
  created() {
    eventHub.$on('MRWidgetUpdateSquash', (val) => {
      this.additionalParams.squash = val;
    });
  },
};
