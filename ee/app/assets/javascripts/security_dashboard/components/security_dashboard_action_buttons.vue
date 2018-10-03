<script>
import Icon from '~/vue_shared/components/icon.vue';
import { mapActions } from 'vuex';

export default {
  name: 'SecurityDashboardActionButtons',
  components: {
    Icon,
  },
  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
  },
  methods: {
    ...mapActions('vulnerabilities', ['openModal']),
  },
};
</script>

<template>
  <div>
    <button
      :aria-label="s__('Reports|More info')"
      class="btn btn-secondary js-more-info"
      type="button"
      @click="openModal(vulnerability)"
    >
      <icon
        name="external-link"
      />
    </button>
  </div>
</template>
