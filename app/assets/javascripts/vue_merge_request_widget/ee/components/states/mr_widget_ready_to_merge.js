import eventHub from '../../../event_hub';
import SquashBeforeMerge from './mr_widget_squash_before_merge';
import ReadyToMergeState from '../../../components/states/mr_widget_ready_to_merge';

export default {
  extends: ReadyToMergeState,
  name: 'MRWidgetReadyToMerge',
  components: {
    'squash-before-merge': SquashBeforeMerge,
  },
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
