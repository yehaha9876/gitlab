<script>
import Icon from '~/vue_shared/components/icon.vue';
import EnvironmentItem from '~/environments/components/environment_item.vue';
import eventHub from '~/environments/event_hub';

export default {
  components: {
    EnvironmentItem,
    Icon,
  },
  inheritAttrs: false,
  props: {
    ...EnvironmentItem.props,
  },
  computed: {
    deployIconName() {
      return this.model.isDeployBoardVisible ? 'chevron-down' : 'chevron-right';
    },
    /**
     * Checkes whether the environment is protected.
     * (`is_protected` currently only set in EE)
     *
     * @returns {Boolean}
     */
    isProtected() {
      return this.model && this.model.is_protected;
    },
    propsPassThrough() {
      const props = Object.keys(EnvironmentItem.props).reduce((acc, prop) => {
        acc[prop] = this[prop];
        return acc;
      }, {});

      return Object.assign(props, this.$attrs);
    },
  },
  methods: {
    toggleDeployBoard() {
      eventHub.$emit('toggleDeployBoard', this.model);
    },
  },
};
</script>

<template>
  <environment-item v-bind="propsPassThrough">
    <template slot="eeDeployBoardIcon">
      <span v-if="model.hasDeployBoard" class="deploy-board-icon" @click="toggleDeployBoard">
        <icon :name="deployIconName" />
      </span>
    </template>
    <template slot="eeIsProtected">
      <span v-if="isProtected" class="badge badge-success">
        {{ s__('Environments|protected') }}
      </span>
    </template>
  </environment-item>
</template>
