<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  data() {
    return {
      isOpen: false,
    };
  },
  methods: {
    handleDropdownToggle() {
      this.isOpen = !this.isOpen;
    },
    handleDropdownClose() {
      this.isOpen = false;
    },
  },
};
</script>

<template>
  <div
    class="prometheus-alert-widget dropdown"
    :class="{ open: isOpen }"
  >
    <button
      class="btn btn-xs alert-dropdown-button"
      type="button"
      @click="handleDropdownToggle"
    >
      <icon
        name="notifications"
        :size="16"
        aria-hidden="true"
      />
      <icon
        name="arrow-down"
        :size="16"
        aria-hidden="true"
        class="chevron"
      />
    </button>
    <div
      ref="dropdownMenu"
      class="dropdown-menu alert-dropdown-menu"
    >
      <div class="dropdown-title">
        <span>Dropdown Title</span>
        <button
          class="dropdown-title-button dropdown-menu-close"
          type="button"
          aria-label="Close"
          @click="handleDropdownClose"
        >
          <icon
            name="close"
            :size="12"
            aria-hidden="true"
          />
        </button>
      </div>
      <div class="dropdown-content">
        Dropdown Form
      </div>
    </div>
  </div>
</template>
