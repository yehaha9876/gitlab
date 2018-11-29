<template>
  <instance-licenses-table-cell class="license-table-expirable-cell" v-bind="$attrs">
    <div slot="value" :class="valueClass">
      {{ dateInWordsValue }} <span v-if="isExpired">- {{ __('Expired') }}</span>
    </div>
  </instance-licenses-table-cell>
</template>

<script>
import { dateInWords } from '~/lib/utils/datetime_utility';
import InstanceLicensesTableCell from './cell.vue';

export default {
  name: 'ExpirableCell',
  inheritAttrs: false,
  props: {
    value: {
      type: [String, Date],
      required: true,
    },
    dateNow: {
      type: Date,
      required: false,
      default() {
        return new Date();
      },
    },
  },
  components: {
    InstanceLicensesTableCell,
  },
  computed: {
    dateInWordsValue() {
      return dateInWords(this.dateValue);
    },
    dateValue() {
      return new Date(this.value);
    },
    isExpired() {
      return this.dateValue < this.dateNow;
    },
    valueClass() {
      return { 'text-danger': this.isExpired };
    },
  },
};
</script>
