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
        this.threshold &&
        this.operator !== this.alertData.operator &&
        this.threshold !== this.alertData.threshold
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
      return this.submitAction === 'create' && !this.haveValuesChanged;
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
        class="btn btn-default active"
      >
        &gt;
      </button>
      <button
        type="button"
        class="btn btn-default"
      >
        =
      </button>
      <button
        type="button"
        class="btn btn-default"
      >
        &lt;
      </button>
    </div>
    <div class="form-group">
      <label>Threshold</label>
      <input
        type="text"
        class="form-control"
      />
    </div>
    <div class="action-group">
      <button
        type="button"
        class="btn btn-default"
      >
        Cancel
      </button>
      <button
        type="button"
        class="btn btn-inverted"
        :class="submitButtonClass"
        :disabled="isSubmitDisabled"
      >
        {{ submitActionText }}
      </button>
    </div>
  </div>
</template>
