<script>
export default {
  props: {
    list: {
      type: Object,
      required: true,
    },
  },
  methods: {
    handleItemClick() {
      this.$emit('onItemSelect', this.list);
    },
  },
};
</script>

<template>
  <li
    class="filter-dropdown-item"
    @click="handleItemClick"
  >
    <button
      class="btn btn-link dropdown-user"
      type="button"
    >
      <div class="dropdown-user-details">
        <div :title="list.title">{{ list.title }}</div>
      </div>
    </button>
  </li>
</template>
