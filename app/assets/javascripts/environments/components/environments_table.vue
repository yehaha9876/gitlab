<script>
/**
 * Render environments table.
 */
import { GlLoadingIcon } from '@gitlab/ui';
import environmentItem from './environment_item.vue';

import deployBoard from 'ee/environments/components/deploy_board_component.vue'; // eslint-disable-line import/order
import CanaryDeploymentCallout from 'ee/environments/components/canary_deployment_callout.vue'; // eslint-disable-line import/order

export default {
  components: {
    environmentItem,
    deployBoard,
    CanaryDeploymentCallout,
    GlLoadingIcon,
  },

  props: {
    environments: {
      type: Array,
      required: true,
      default: () => [],
    },

    canReadEnvironment: {
      type: Boolean,
      required: false,
      default: false,
    },

    canCreateDeployment: {
      type: Boolean,
      required: false,
      default: false,
    },

    canaryDeploymentFeatureId: {
      type: String,
      required: true,
    },

    showCanaryDeploymentCallout: {
      type: Boolean,
      required: true,
    },

    userCalloutsPath: {
      type: String,
      required: true,
    },

    lockPromotionSvgPath: {
      type: String,
      required: true,
    },

    helpCanaryDeploymentsPath: {
      type: String,
      required: true,
    },
  },
  methods: {
    folderUrl(model) {
      return `${window.location.pathname}/folders/${model.folderName}`;
    },
    shouldRenderFolderContent(env) {
      return env.isFolder && env.isOpen && env.children && env.children.length > 0;
    },
    shouldShowCanaryCallout(env) {
      return env.showCanaryCallout && this.showCanaryDeploymentCallout;
    }
  }
};
</script>
<template>
  <div class="ci-table" role="grid">
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section section-15 environments-name" role="columnheader">
        {{ s__('Environments|Environment') }}
      </div>
      <div class="table-section section-10 environments-deploy" role="columnheader">
        {{ s__('Environments|Deployment') }}
      </div>
      <div class="table-section section-15 environments-build" role="columnheader">
        {{ s__('Environments|Job') }}
      </div>
      <div class="table-section section-20 environments-commit" role="columnheader">
        {{ s__('Environments|Commit') }}
      </div>
      <div class="table-section section-10 environments-date" role="columnheader">
        {{ s__('Environments|Updated') }}
      </div>
    </div>
    <template v-for="(model, i) in environments" :model="model">
      <div
        is="environment-item"
        :key="`environment-item-${i}`"
        :model="model"
        :can-create-deployment="canCreateDeployment"
        :can-read-environment="canReadEnvironment"
      />

      <div
        v-if="model.hasDeployBoard && model.isDeployBoardVisible"
        :key="`deploy-board-row-${i}`"
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

      <template v-if="shouldRenderFolderContent(model)">
        <div v-if="model.isLoadingFolderContent" :key="`loading-item-${i}`">
          <gl-loading-icon :size="2" class="prepend-top-16" />
        </div>

        <template v-else>
          <div
            is="environment-item"
            v-for="(children, index) in model.children"
            :key="`env-item-${i}-${index}`"
            :model="children"
            :can-create-deployment="canCreateDeployment"
            :can-read-environment="canReadEnvironment"
          />

          <div :key="`sub-div-${i}`">
            <div class="text-center prepend-top-10">
              <a :href="folderUrl(model)" class="btn btn-default">
                {{ s__('Environments|Show all') }}
              </a>
            </div>
          </div>
        </template>
      </template>

      <template
        v-if="shouldShowCanaryCallout(model)"
      >
        <canary-deployment-callout
          :key="`canary-promo-${i}`"
          :canary-deployment-feature-id="canaryDeploymentFeatureId"
          :user-callouts-path="userCalloutsPath"
          :lock-promotion-svg-path="lockPromotionSvgPath"
          :help-canary-deployments-path="helpCanaryDeploymentsPath"
        />
      </template>
    </template>
  </div>
</template>
