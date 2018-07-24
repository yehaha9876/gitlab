<script>
import AssigneesListItem from './assignees_list_item.vue';

export default {
  components: {
    AssigneesListItem,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    listItemComponent: {
      type: Object,
      required: true,
    },
  },
  methods: {
    handleItemClick(item) {
      this.$emit('onItemSelect', item);
    },
  },
};
</script>

<template>
  <div class="dropdown-content">
    <ul>
      <component
        v-for="item in items"
        :key="item.id"
        :list="item"
        :is="listItemComponent"
        @onItemSelect="handleItemClick"
      />
    </ul>
  </div>
</template>
