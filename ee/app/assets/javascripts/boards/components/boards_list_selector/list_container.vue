<script>
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';

import ListFilter from './list_filter.vue';
import ListContent from './list_content.vue';

export default {
  components: {
    LoadingIcon,
    ListFilter,
    ListContent,
  },
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    listItemComponent: {
      type: Object,
      required: true,
    },
    filterItems: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      query: '',
    };
  },
  computed: {
    filteredItems() {
      if (!this.query) return this.items;

      return this.filterItems(this.query, this.items);
    },
  },
  methods: {
    handleSearch(query) {
      this.query = query;
    },
    handleItemClick(item) {
      this.$emit('onItemSelect', item);
    },
  },
};
</script>

<template>
  <div class="dropdown-assignees-list">
    <div
      v-if="loading"
      class="dropdown-loading"
    >
      <loading-icon />
    </div>
    <list-filter
      @onSearchInput="handleSearch"
    />
    <list-content
      v-if="!loading"
      :items="filteredItems"
      :list-item-component="listItemComponent"
      @onItemSelect="handleItemClick"
    />
  </div>
</template>
