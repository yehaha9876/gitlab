<script>
import { __ } from '~/locale';
import Vue from 'vue';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

const SUBMIT_ACTION_TEXT = {
  create: __('Add'),
  update: __('Save'),
  delete: __('Delete'),
};

const SUBMIT_BUTTON_CLASS = {
  create: 'btn-create',
  update: 'btn-save',
  delete: 'btn-remove',
};

const OPERATORS = {
  greaterThan: '>',
  equalTo: '=',
  lessThan: '<',
};

export default {
  props: {
    disabled: {
      type: Boolean,
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
    alert: {
      type: String,
      required: false,
      default: null,
    },
    alertData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      operators: OPERATORS,
      operator: this.alertData.operator,
      threshold: this.alertData.threshold,
    };
  },
  computed: {
    haveValuesChanged() {
      return (
        this.operator &&
        this.threshold === Number(this.threshold) &&
        (this.operator !== this.alertData.operator || this.threshold !== this.alertData.threshold)
      );
    },
    submitAction() {
      if (!this.alert) return 'create';
      if (this.haveValuesChanged) return 'update';
      return 'delete';
    },
    submitActionText() {
      return SUBMIT_ACTION_TEXT[this.submitAction];
    },
    submitButtonClass() {
      return SUBMIT_BUTTON_CLASS[this.submitAction];
    },
    isSubmitDisabled() {
      return this.disabled || (this.submitAction === 'create' && !this.haveValuesChanged);
    },
  },
  watch: {
    alertData() {
      this.resetAlertData();
    },
  },
  methods: {
    handleCancel() {
      this.resetAlertData();
      this.$emit('cancel');
    },
    handleSubmit() {
      this.$refs.submitButton.blur();
      this.$emit(this.submitAction, {
        alert: this.alert,
        name: this.name,
        query: this.query,
        operator: this.operator,
        threshold: this.threshold,
      });
    },
    resetAlertData() {
      this.operator = this.alertData.operator;
      this.threshold = this.alertData.threshold;
    },
  },
};
</script>

<template>
  <div class="alert-form">
    <div
      class="form-group btn-group"
      role="group"
      :aria-label="s__('PrometheusAlerts|Operator')"
    >
      <button
        type="button"
        class="btn btn-default"
        :class="{ active: operator === operators.greaterThan }"
        @click="operator = operators.greaterThan"
        :disabled="disabled"
      >
        {{ operators.greaterThan }}
      </button>
      <button
        type="button"
        class="btn btn-default"
        :class="{ active: operator === operators.equalTo }"
        @click="operator = operators.equalTo"
        :disabled="disabled"
      >
        {{ operators.equalTo }}
      </button>
      <button
        type="button"
        class="btn btn-default"
        :class="{ active: operator === operators.lessThan }"
        @click="operator = operators.lessThan"
        :disabled="disabled"
      >
        {{ operators.lessThan }}
      </button>
    </div>
    <div class="form-group">
      <label>{{ s__('PrometheusAlerts|Threshold') }}</label>
      <input
        type="number"
        class="form-control"
        v-model.number="threshold"
        :disabled="disabled"
      />
    </div>
    <div class="action-group">
      <button
        type="button"
        class="btn btn-default"
        @click="handleCancel"
        :disabled="disabled"
      >
        {{ __('Cancel') }}
      </button>
      <button
        ref="submitButton"
        type="button"
        class="btn btn-inverted"
        :class="submitButtonClass"
        :disabled="isSubmitDisabled"
        @click="handleSubmit"
      >
        {{ submitActionText }}
      </button>
    </div>
  </div>
</template>
