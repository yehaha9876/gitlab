<template>
  <instance-licenses-table-cell class="license-table-info-cell" v-bind="$attrs">
    <template slot="title">
      <span class="mr-2 text">{{ title }}</span>
      <button type="button" class="btn-link information-target" :class="popoverTargetClass">
        <icon name="information" css-classes="icon" />
      </button>
      <gl-popover
        placement="bottom"
        :target="this.popoverTarget"
        triggers="focus"
        class="license-table-info-popover"
        container="license-list"
      >
        <template slot="title"
          ><slot name="popover-title">{{ popoverTitle }}</slot></template
        >
        <slot></slot>
      </gl-popover>
    </template>
  </instance-licenses-table-cell>
</template>

<script>
import { GlPopover } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import InstanceLicensesTableCell from './cell.vue';

export default {
  name: 'InfoCell',
  inheritAttrs: false,
  props: {
    title: {
      type: String,
      required: true,
    },
    popoverTitle: {
      type: String,
      required: false,
    },
  },
  components: {
    Icon,
    GlPopover,
    InstanceLicensesTableCell,
  },
  data() {
    return {
      popoverTarget: null,
      popoverTargetClass: 'popover-target',
    };
  },
  mounted() {
    this.popoverTarget = this.$el.querySelector(`.${this.popoverTargetClass}`);
  },
};
</script>
