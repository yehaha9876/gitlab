<script>
import { mapState } from 'vuex';
import GlFilter from './filter.vue';

export default {
  components: {
    GlFilter,
  },
  props: {
    dashboardDocumentation: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('filters', ['filters']),
  },
};
</script>

<template>
  <div class="dashboard-filters">
    <div class="row mx-0 p-2">
      <gl-filter
        v-for="filter in filters"
        :key="filter.id"
        :filter-id="filter.id"
        class="col-sm p-2 js-filter"
        :dashboard-documentation="dashboardDocumentation"
        @change="$emit('change');"
      />
      <div class="col-sm p-2 d-md-block d-none"></div>
      <div class="col-sm p-2 d-md-block d-none"></div>
      <div class="col-sm p-2 d-md-block d-none"></div>
    </div>
  </div>
</template>

<style>
.dashboard-filters {
  background-color: #fafafa;
  border-bottom: 1px solid #e5e5e5;
}
</style>
