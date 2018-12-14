<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mapGetters, mapMutations } from 'vuex';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  data: () => ({
    filterId: 'type',
  }),
  computed: {
    ...mapGetters('filters', ['getFilter', 'getSelectedOption']),
    filter() {
      return this.getFilter(this.filterId);
    },
    selectedOptionText() {
      const selectedOption = this.getSelectedOption(this.filterId);
      return (selectedOption && selectedOption.name) || '-';
    },
  },
  methods: {
    ...mapMutations('filters', ['SET_FILTER']),
    clickFilter(option) {
      const { filterId } = this;
      const optionId = option.id;
      this.SET_FILTER({ filterId, optionId });
    },
  },
};
</script>

<template>
  <div class="dashboard-filters">
    <div class="dashboard-filter">
      <strong>{{ filter.name }}</strong>
      <gl-dropdown :text="selectedOptionText">
        <gl-dropdown-item
          v-for="option in filter.options"
          :key="option.id"
          @click="clickFilter(option);"
          >{{ option.name }}</gl-dropdown-item
        >
      </gl-dropdown>
    </div>
  </div>
</template>

<style>
.dashboard-filters {
  padding: 16px;
  background-color: #fafafa;
  border-bottom: 1px solid #e5e5e5;
}
.dashboard-filter {
  width: 20%;
}
.dashboard-filter .b-dropdown {
  margin-top: 4px;
  display: block;
}
.dashboard-filter .dropdown-toggle {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}
</style>
