<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import TerminalSession from './session.vue';
import EmptyState from './empty_state.vue';

export default {
  components: {
    EmptyState,
    TerminalSession,
  },
  computed: {
    ...mapState('terminal', ['isShowSplash', 'paths']),
    ...mapGetters('terminal', ['environmentCheck']),
  },
  methods: {
    ...mapActions('terminal', ['startSession', 'hideSplash']),
    start() {
      this.hideSplash();
      this.startSession();
    },
  },
};
</script>

<template>
  <div class="h-100">
    <div
      v-if="isShowSplash"
      class="h-100 d-flex flex-column justify-content-center"
    >
      <empty-state
        :is-loading="environmentCheck.isLoading"
        :is-valid="environmentCheck.isValid"
        :message="environmentCheck.message"
        :help-path="paths.webTerminalHelpPath"
        :illustration-path="paths.webTerminalSvgPath"
        @start="start()"
      />
    </div>
    <template
      v-else
    >
      <terminal-session />
    </template>
  </div>
</template>
