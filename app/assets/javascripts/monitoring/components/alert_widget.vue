<script>
import Icon from '~/vue_shared/components/icon.vue';
import AlertWidgetForm from './alert_widget_form.vue';
import AlertsService from '../services/alerts_service';

let alertId = 1;
const generateAlertPath = () => {
  alertId += 1;
  return `alert${alertId}.json`;
};

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
    name: {
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
      service: null,
      isLoading: false,
      isOpen: false,
      alerts: this.currentAlerts,
      alertData: {},
    };
  },
  computed: {
    alertSummary() {
      const data = this.firstAlertData;
      if (!data) return null;
      return `${this.name} ${data.operator} ${data.threshold}`;
    },
    alertIcon() {
      return this.hasAlerts ? 'notifications' : 'notifications-off';
    },
    dropdownTitle() {
      return this.hasAlerts ? 'Edit alert' : 'Add alert';
    },
    hasAlerts() {
      return this.alerts.length > 0;
    },
    firstAlert() {
      return this.hasAlerts ? this.alerts[0] : undefined;
    },
    firstAlertData() {
      return this.hasAlerts ? this.alertData[this.alerts[0]] : undefined;
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
  created() {
    this.service = new AlertsService({ alertsEndpoint: this.alertsEndpoint });
    this.fetchAlertData();
  },
  beforeDestroy() {
    // clean up external event listeners
    document.removeEventListener('click', this.handleOutsideClick);
  },
  methods: {
    fetchAlertData() {
      this.isLoading = true;
      return Promise.all(
        this.alerts.map(alertPath =>
          this.service
            .readAlert(alertPath)
            .then(alertData => this.$set(this.alertData, alertPath, alertData)),
        ),
      )
        .then(() => {
          this.isLoading = false;
        })
        .catch(() => {
          // TODO: produce an error message and/or fail state
          this.isLoading = false;
        });
    },
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
    handleCreate({ name, query, operator, threshold }) {
      const newAlert = { name, query, operator, threshold };
      this.isLoading = true;
      this.service
        .createAlert(newAlert)
        .then(() => {
          const alertPath = generateAlertPath();
          this.alerts.unshift(alertPath);
          this.$set(this.alertData, alertPath, newAlert);
          this.isLoading = false;
          this.handleDropdownClose();
        })
        .catch(() => {
          // TODO: add error handling
        });
    },
    handleUpdate({ alert, name, query, operator, threshold }) {
      const updatedAlert = { name, query, operator, threshold };
      this.isLoading = true;
      this.service
        .updateAlert(alert, updatedAlert)
        .then(() => {
          this.$set(this.alertData, alert, updatedAlert);
          this.isLoading = false;
          this.handleDropdownClose();
        })
        .catch(() => {
          // TODO: add error handling
        });
    },
    handleDelete({ alert }) {
      this.isLoading = true;
      this.service
        .deleteAlert(alert)
        .then(() => {
          this.$delete(this.alertData, alert);
          this.alerts = this.alerts.filter(alertPath => alert !== alertPath);
          this.isLoading = false;
          this.handleDropdownClose();
        })
        .catch(() => {
          // TODO: add error handling
        });
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
          :alert="firstAlert"
          :alert-data="firstAlertData"
          :query="query"
          @create="handleCreate"
          @update="handleUpdate"
          @delete="handleDelete"
          @cancel="handleDropdownClose"
        />
      </div>
    </div>
  </div>
</template>
