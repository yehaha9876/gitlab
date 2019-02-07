<script>
import { mapState } from 'vuex';
import EnvironmentsTable from '~/environments/components/environments_table.vue';
import CanaryDeploymentCallout from 'ee/environments/components/canary_deployment_callout.vue';

export default {
  components: {
    EnvironmentsTable,
    CanaryDeploymentCallout,
  },
  inheritAttrs: false,
  computed: {
    ...mapState(['showCanaryDeploymentCallout']),
  },
  methods: {
    shouldShowCanaryCallout(env) {
      return env.showCanaryCallout && this.showCanaryDeploymentCallout;
    },
  },
};
</script>

<template>
  <environments-table v-bind="$attrs">
    <template slot="eeCanaryDeploymentCallout" slot-scope="{ model, index }">
      <canary-deployment-callout
        v-if="shouldShowCanaryCallout(model)"
        :key="`canary-promo-${index}`"
        :data-js-canary-promo-key="index"
      />
    </template>
  </environments-table>
</template>
