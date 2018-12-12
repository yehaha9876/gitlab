<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  data: () => ({
    selected: 0,
    scannerTypes: [
      {
        id: 0,
        name: 'All',
      },
      {
        id: 1,
        name: 'SAST',
      },
      {
        id: 2,
        name: 'DAST',
      },
    ],
  }),
  computed: {
    selectedItem() {
      return this.scannerTypes[this.selected];
    }
  },
  methods: {
    clickFilter(item) {
      this.selected = item.id
    },
  },
};
</script>

<template>
  <div class="dashboard-filters">
      <div class="dashboard-filter">
        <strong>Report type</strong>
        <gl-dropdown :text="selectedItem.name">
          <gl-dropdown-item
            v-for="item in scannerTypes"
            :key="item.id"
            @click="clickFilter(item)"
          >{{
            item.name
          }}</gl-dropdown-item>
        </gl-dropdown>
      </div>
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
