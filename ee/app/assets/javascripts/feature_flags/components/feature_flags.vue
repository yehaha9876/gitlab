<script>
import FeatureFlagsTable from './feature_flags_table.vue';
import FeatureFlagsService from '../services/feature_flags_service';
import featureFlagsMixin from '../mixins/feature_flags';
import { __ } from '~/locale';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import TablePagination from '~/vue_shared/components/table_pagination.vue';
import { getParameterByName } from '~/lib/utils/common_utils';
import CIPaginationMixin from '~/vue_shared/mixins/ci_pagination_api_mixin';

export default {
  components: {
    FeatureFlagsTable,
    NavigationTabs,
    TablePagination,
  },
  mixins: [featureFlagsMixin, CIPaginationMixin],
  props: {
    store: {
      type: Object,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    csrfToken: {
      type: String,
      required: true,
    },
    errorStateSvgPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
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
    shouldRenderPagination() {
      return (
        !this.isLoading &&
        !this.hasError &&
        this.state.featureFlags.length &&
        this.state.pageInfo.total > this.state.pageInfo.perPage
      );
    },
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
    this.requestData = { scope: this.scope, page: this.page };
  },
};
</script>
<template>
  <div>
    <div class="top-area scrolling-tabs-container inner-page-scroll-tabs">
      <navigation-tabs :tabs="tabs" scope="featureflags" @onChangeTab="onChangeTab" />
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

    <template v-else-if="shouldRenderTable">
      <feature-flags-table :csrf-token="csrfToken" :feature-flags="state.featureFlags" />
    </template>

    <table-pagination
      v-if="shouldRenderPagination"
      :change="onChangePage"
      :page-info="state.pageInfo"
    />
  </div>
</template>
