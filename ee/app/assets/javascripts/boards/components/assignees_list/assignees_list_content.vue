<script>
import AssigneesListItem from './assignees_list_item.vue';

export default {
  components: {
    AssigneesListItem,
  },
  props: {
    assignees: {
      type: Array,
      required: true,
    },
    listItemComponent: {
      type: Object,
      required: true,
    },
  },
  methods: {
    handleItemClick(assignee) {
      this.$emit('onItemSelect', assignee);
    },
  },
};
</script>

<template>
  <div class="dropdown-content">
    <ul>
      <component
        v-for="assignee in assignees"
        :key="assignee.id"
        :list="assignee"
        :is="listItemComponent"
        @onItemSelect="handleItemClick"
      />
    </ul>
  </div>
</template>
