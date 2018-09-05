<script>
/**
 * Render environments table.
 */
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import environmentItem from './environment_item.vue';

import deployBoard from 'ee/environments/components/deploy_board_component.vue'; // eslint-disable-line import/first

const hasSecurityReport = environments =>
  environments.some(
    env =>
      (!env.isFolder && env.security_reports && env.security_reports.has_security_reports) ||
      (Array.isArray(env.children) && hasSecurityReport(env.children)),
  );

export default {
  components: {
    environmentItem,
    loadingIcon,
    deployBoard,
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
  },

  computed: {
    hasSecurityReport() {
      return hasSecurityReport(this.environments);
    },
  },

  methods: {
    folderUrl(model) {
      return `${window.location.pathname}/folders/${model.folderName}`;
    },
    shouldRenderFolderContent(env) {
      return env.isFolder && env.isOpen && env.children && env.children.length > 0;
    },
  },
};
</script>
<template>
  <div
    class="ci-table"
    role="grid"
  >
    <div
      class="gl-responsive-table-row table-row-header"
      role="row"
    >
      <div
        class="table-section section-15 environments-name"
        role="columnheader"
      >
        {{ s__("Environments|Environment") }}
      </div>
      <div
        class="table-section section-10 environments-deploy"
        role="columnheader"
      >
        {{ s__("Environments|Deployment") }}
      </div>
      <div
        class="table-section section-15 environments-build"
        role="columnheader"
      >
        {{ s__("Environments|Job") }}
      </div>
      <div
        class="table-section section-20 environments-commit"
        role="columnheader"
      >
        {{ s__("Environments|Commit") }}
      </div>
      <!-- EE-Specific -->
      <div
        v-if="hasSecurityReport"
        class="table-section section-10 environments-security"
        role="columnheader"
      >
        {{ s__("Environments|Security") }}
      </div>
      <!-- EE-Specific -->
      <div
        class="table-section section-10 environments-date"
        role="columnheader"
      >
        {{ s__("Environments|Updated") }}
      </div>
    </div>
    <template
      v-for="(model, i) in environments"
      :model="model">
      <environment-item
        :model="model"
        :can-create-deployment="canCreateDeployment"
        :can-read-environment="canReadEnvironment"
        :has-security-report="hasSecurityReport"
        :key="`environment-item-${i}`"
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

      <template
        v-if="shouldRenderFolderContent(model)"
      >
        <div
          v-if="model.isLoadingFolderContent"
          :key="`loading-item-${i}`">
          <loading-icon size="2" />
        </div>

        <template v-else>
          <environment-item
            v-for="(children, index) in model.children"
            :model="children"
            :can-create-deployment="canCreateDeployment"
            :can-read-environment="canReadEnvironment"
            :has-security-report="hasSecurityReport"
            :key="`env-item-${i}-${index}`"
          />

          <div :key="`sub-div-${i}`">
            <div class="text-center prepend-top-10">
              <a
                :href="folderUrl(model)"
                class="btn btn-default"
              >
                {{ s__("Environments|Show all") }}
              </a>
            </div>
          </div>
        </template>
      </template>
    </template>
  </div>
</template>
