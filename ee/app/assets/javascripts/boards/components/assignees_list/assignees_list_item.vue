<script>
import { sprintf, __ } from '~/locale';

export default {
  props: {
    list: {
      type: Object,
      required: true,
    },
  },
  computed: {
    avatarAltText() {
      return sprintf(__("%{name}'s avatar"), {
        name: this.list.name,
      });
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
      <div class="avatar-container s32">
        <img
          :alt="avatarAltText"
          :src="list.avatar_url"
          class="avatar s32 lazy"
        />
      </div>
      <div class="dropdown-user-details">
        <div :title="list.name">{{ list.name }}</div>
        <div
          :title="list.username"
          class="dropdown-light-content"
        >@{{ list.username }}</div>
      </div>
    </button>
  </li>
</template>
