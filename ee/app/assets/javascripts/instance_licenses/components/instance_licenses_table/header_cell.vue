<template>
  <instance-licenses-table-cell class="license-table-header-cell">
    <template slot="title">
      <icon class="icon" :name="icon" /> <span class="text font-weight-bold">{{ title }}</span>
    </template>
  </instance-licenses-table-cell>
</template>

<script>
import Icon from '~/vue_shared/components/icon.vue';
import InstanceLicensesTableCell from './cell.vue';

export default {
  name: 'HeaderCell',
  props: {
    title: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      required: true,
    },
  },
  components: {
    Icon,
    InstanceLicensesTableCell,
  },
};
</script>
