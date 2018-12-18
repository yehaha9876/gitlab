<script>
import FeatureFlagsTable from './feature_flags_table.vue';
import FeatureFlagsService from '../services/feature_flags_service';
import featureFlagsMixin from '../mixins/feature_flags';
import { __ } from '../../../../../../app/assets/javascripts/locale';
import NavigationTabs from '../../../../../../app/assets/javascripts/vue_shared/components/navigation_tabs.vue';
import { getParameterByName } from '../../../../../../app/assets/javascripts/lib/utils/common_utils';
import CIPaginationMixin from '../../../../../../app/assets/javascripts/vue_shared/mixins/ci_pagination_api_mixin';

export default {
  components: {
    FeatureFlagsTable,
    NavigationTabs,
  },
  mixins: [featureFlagsMixin, CIPaginationMixin],
  props: {
    store: {
      type: Object,
      required: true,
    },
    canDeleteFeatureFlag: {
      type: Boolean,
      required: true,
    },
    canUpdateFeatureFlag: {
      type: Boolean,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    instanceId: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    test: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      // Start with loading state to avoid a glitch when the empty state will be rendered
      isLoading: true,
      state: this.store.state,
      scope: getParameterByName('scope') || 'all',
      page: getParameterByName('page') || '1',
      requestData: {},
    };
  },
  scopes: {
    all: 'all',
    enabled: 'enabled',
    disabled: 'disabled',
  },
  computed: {
    shouldRenderTable() {
      return !this.isLoading && this.state.featureFlags.length > 0 && !this.hasError;
    },
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },
    tabs() {
      const { count } = this.state;
      const { scopes } = this.$options;

      return [
        {
          name: __('All'),
          scope: scopes.all,
          count: count.all,
          isActive: this.scope === 'all',
        },
        {
          name: __('Enabled'),
          scope: scopes.enabled,
          count: count.enabled,
          isActive: this.scope === 'enabled',
        },
        {
          name: __('Disabled'),
          scope: scopes.disabled,
          count: count.disabled,
          isActive: this.scope === 'disabled',
        },
      ];
    },
  },
  created() {
    this.service = new FeatureFlagsService(this.endpoint);
    this.requestData = { scope: this.scope, page: this.page, instance_id: this.instanceId };
  },
};
</script>
<template>
  <div>
    <div class="top-area scrolling-tabs-container inner-page-scroll-tabs">
      <navigation-tabs :tabs="tabs" scope="featureflags" @onChangeTab="onChangeTab"/>
    </div>

    <gl-loading-icon
      v-if="isLoading"
      :label="s__('Pipelines|Loading Pipelines')"
      :size="3"
      class="prepend-top-20"
    />

    <svg-blank-state
      v-else-if="shouldRenderErrorState"
      :svg-path="errorStateSvgPath"
      :message="
        s__(`FeatureFlags|There was an error fetching the feature flags.
      Try again in a few moments or contact your support team.`)
      "
    />

    <div v-else-if="shouldRenderTable" class="table-holder">
      <feature-flags-table
        :can-delete-feature-flag="canDeleteFeatureFlag"
        :can-update-feature-flag="canUpdateFeatureFlag"
        :feature-flags="state.featureFlags"
      />
    </div>

    <table-pagination
      v-if="shouldRenderPagination"
      :change="onChangePage"
      :page-info="state.pageInfo"
    />
  </div>
</template>
