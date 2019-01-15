<script>
import CeDashboard from '~/monitoring/components/dashboard.vue';
import AlertWidget from './alert_widget.vue';
import Graph from './graph.vue';
import ThresholdLines from './threshold_lines.vue';

export default {
  extends: CeDashboard,
  components: {
    AlertWidget,
    Graph,
    ThresholdLines,
  },
  props: {
    alertsEndpoint: {
      type: String,
      required: false,
      default: null,
    },
  },
  inheritAttrs: false,
};
</script>
