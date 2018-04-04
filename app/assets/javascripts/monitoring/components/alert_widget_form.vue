<script>
const SUBMIT_ACTION_TEXT = {
  create: 'Add',
  update: 'Save',
  delete: 'Delete',
};

const SUBMIT_BUTTON_CLASS = {
  create: 'btn-create',
  update: 'btn-save',
  delete: 'btn-remove',
};

export default {
  props: {
    isLoading: {
      type: Boolean,
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
      operator: this.alertData.operator,
      threshold: this.alertData.threshold,
    };
  },
  computed: {
    haveValuesChanged() {
      return (
        this.operator &&
        this.threshold === Number(this.threshold) &&
        (this.operator !== this.alertData.operator ||
          this.threshold !== this.alertData.threshold)
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
      return (
        this.isLoading ||
        (this.submitAction === 'create' && !this.haveValuesChanged)
      );
    },
  },
  methods: {
    handleCancel() {
      this.operator = this.alertData.operator;
      this.threshold = this.alertData.threshold;
      this.$emit('cancel');
    },
    handleSubmit() {
      this.$refs.submitButton.blur();
      this.$emit(this.submitAction, {
        alert: this.alert,
        query: this.query,
        operator: this.operator,
        threshold: this.threshold,
      });
    },
  },
};
</script>

<template>
  <div class="alert-form">
    <div
      class="form-group btn-group"
      role="group"
      aria-label="Operator"
    >
      <button
        type="button"
        class="btn btn-default"
        :class="{ active: operator === '>' }"
        @click="operator = '>'"
        :disabled="isLoading"
      >
        &gt;
      </button>
      <button
        type="button"
        class="btn btn-default"
        :class="{ active: operator === '=' }"
        @click="operator = '='"
        :disabled="isLoading"
      >
        =
      </button>
      <button
        type="button"
        class="btn btn-default"
        :class="{ active: operator === '<' }"
        @click="operator = '<'"
        :disabled="isLoading"
      >
        &lt;
      </button>
    </div>
    <div class="form-group">
      <label>Threshold</label>
      <input
        type="number"
        class="form-control"
        v-model.number="threshold"
        :disabled="isLoading"
      />
    </div>
    <div class="action-group">
      <button
        type="button"
        class="btn btn-default"
        @click="handleCancel"
        :disabled="isLoading"
      >
        Cancel
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
