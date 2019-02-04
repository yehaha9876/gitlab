<script>
import { mapState } from 'vuex';
import EnvironmentsTable from '~/environments/components/environments_table.vue';
import CanaryDeploymentCallout from 'ee/environments/components/canary_deployment_callout.vue';
import DeployBoard from 'ee/environments/components/deploy_board_component.vue';

export default {
  components: {
    EnvironmentsTable,
    CanaryDeploymentCallout,
    DeployBoard,
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
    <template slot="eeDeployBoard" slot-scope="{ model, index }">
      <div
        v-if="model.hasDeployBoard && model.isDeployBoardVisible"
        :key="`deploy-board-row-${index}`"
        class="js-deploy-board-row"
      >
        <div class="deploy-board-container">
          <deploy-board
            :deploy-board-data="model.deployBoardData"
            :is-loading="model.isLoadingDeployBoard"
            :is-empty="model.isEmptyDeployBoard"
            :logs-path="model.logs_path"
          />
        </div>
      </div>
    </template>
    <template slot="eeCanaryDeploymentCallout" slot-scope="{ model, index }">
      <canary-deployment-callout
        v-if="shouldShowCanaryCallout(model)"
        :key="`canary-promo-${index}`"
        :data-js-canary-promo-key="index"
      />
    </template>
  </environments-table>
</template>
