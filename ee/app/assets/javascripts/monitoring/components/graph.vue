<script>
import CeGraph from '~/monitoring/components/graph.vue';

export default {
  extends: CeGraph,
  components: {
    CeGraph,
  },
  data() {
    return {
      alertsEndpoint: '',
      alertData: {},
    };
  },
  inheritAttrs: false,
  mounted() {
    this.alertsEndpoint = window.alertsEndpoint; // TODO: put this in store.
  },
  methods: {
    getGraphLabel(graphData) {
      if (!graphData.queries || !graphData.queries[0]) return undefined;
      return graphData.queries[0].label || graphData.y_label || 'Average';
    },
    getQueryAlerts(graphData) {
      if (!graphData.queries) return [];
      return graphData.queries.map(query => query.alert_path).filter(Boolean);
    },
    setAlerts(metricId, alertData) {
      this.$set(this.alertData, metricId, alertData);
    },
  },
};
</script>

<template>
  <ce-graph v-bind="$props">
    <!-- EE content -->
    <template slot="additionalSvgContent">
      <threshold-lines
        operator="<"
        :threshold="0.01"
        :graph-draw-data="graphDrawData"
      />
      <alert-widget
        v-if="alertsEndpoint && graphData.id"
        :alerts-endpoint="alertsEndpoint"
        :label="getGraphLabel(graphData)"
        :current-alerts="getQueryAlerts(graphData)"
        :custom-metric-id="graphData.id"
        :alert-data="alertData[graphData.id]"
        @setAlerts="setAlerts"
      />
    </template>
  </ce-graph>
</template>