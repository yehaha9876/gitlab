<script>
import Icon from '~/vue_shared/components/icon.vue';
import AlertWidgetForm from './alert_widget_form.vue';

export default {
  components: {
    Icon,
    AlertWidgetForm,
  },
  props: {
    alertsEndpoint: {
      type: String,
      required: true,
    },
    query: {
      type: String,
      required: true,
    },
    currentAlerts: {
      type: Array,
      require: false,
      default: () => [],
    },
  },
  data() {
    return {
      isLoading: false,
      isOpen: false,
      alerts: this.currentAlerts,
    };
  },
  computed: {
    alertSummary() {
      return this.hasAlerts ? 'alert summary' : null;
    },
    alertIcon() {
      return this.hasAlerts
        ? 'notifications'
        : 'notifications-off';
    },
    dropdownTitle() {
      return this.hasAlerts
        ? 'Edit alert'
        : 'Add alert';
    },
    hasAlerts() {
      return this.alerts.length > 0;
    },
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
    <span class="alert-current-setting">
      <i
        v-if="isLoading"
        class="fa fa-spinner fa-spin"
        aria-hidden="true">
      </i>
      {{ alertSummary }}
    </span>
    <button
      class="btn btn-xs alert-dropdown-button"
      type="button"
      @click="handleDropdownToggle"
    >
      <icon
        :name="alertIcon"
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
        <span>{{ dropdownTitle }}</span>
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
        <alert-widget-form
          :is-loading="isLoading"
          :alert="alerts[0]"
          :query="query"
        />
      </div>
    </div>
  </div>
</template>
