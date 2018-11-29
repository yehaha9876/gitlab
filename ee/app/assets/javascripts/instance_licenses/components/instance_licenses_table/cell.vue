<template>
  <div class="license-table-cell">
    <span class="title"
      ><slot name="title">{{ title }}</slot></span
    >
    <div class="value mt-2" :class="valueClass">
      <slot name="value">{{ value }}</slot>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Cell',
  props: {
    title: {
      type: String,
      required: false,
      default: null,
    },
    value: {
      type: [String, Number],
      required: false,
      default: null,
    },
  },
  computed: {
    isNumber() {
      return Number.isInteger(this.value);
    },
    isString() {
      return typeof this.value === 'string' && this.value !== '';
    },
    isValidValue() {
      return this.isNumber || this.isString;
    },
    valueClass() {
      return { 'number-value': this.isNumber, 'string-value': this.isString };
    },
  },
};
</script>
