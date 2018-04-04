<script>
import Icon from '~/vue_shared/components/icon.vue';
import AlertWidgetForm from './alert_widget_form.vue';

export default {
  components: {
    Icon,
    AlertWidgetForm,
  },
  data() {
    return {
      isOpen: false,
    };
  },
  watch: {
    isOpen(open) {
      if (open) {
        document.addEventListener('click', this.handleOutsideClick);
      } else {
        document.removeEventListener('click', this.handleOutsideClick);
      }
    },
  },
  beforeDestroy() {
    // clean up external event listeners
    document.removeEventListener('click', this.handleOutsideClick);
  },
  methods: {
    handleDropdownToggle() {
      this.isOpen = !this.isOpen;
    },
    handleDropdownClose() {
      this.isOpen = false;
    },
    handleOutsideClick(event) {
      if (!this.$refs.dropdownMenu.contains(event.target)) {
        this.isOpen = false;
      }
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
        <alert-widget-form />
      </div>
    </div>
  </div>
</template>
