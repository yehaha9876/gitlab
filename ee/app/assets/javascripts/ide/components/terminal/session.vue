<script>
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import Terminal from './terminal.vue';
import {
  STATUS_RUNNING,
  STATUS_STARTING,
  STATUS_STOPPED,
} from '../../constants';

export default {
  components: {
    Terminal,
  },
  computed: {
    ...mapState('terminal', ['sessionPath', 'sessionStatus']),
    actionButton() {
      if (!this.sessionPath) {
        return null;
      }

      if (this.sessionStatus === STATUS_STOPPED) {
        return {
          action: () => this.restartSession(),
          text: __('Restart Terminal'),
          class: 'btn-primary',
        };
      } else if (this.sessionStatus === STATUS_STARTING || this.sessionStatus === STATUS_RUNNING) {
        return {
          action: () => this.stopSession(),
          text: __('Stop Terminal'),
          class: 'btn-inverted btn-remove',
        };
      }

      return null;
    },
  },
  methods: {
    ...mapActions('terminal', ['restartSession', 'stopSession']),
  },
};
</script>

<template>
  <div class="ide-terminal build-page d-flex flex-column">
    <header
      class="ide-job-header d-flex align-items-center"
    >
      <h5>{{ __('Web Terminal') }}</h5>
      <div class="ml-auto align-self-center">
        <button
          v-if="actionButton"
          type="button"
          class="btn btn-sm"
          :class="actionButton.class"
          @click="actionButton.action"
          v-text="actionButton.text"
        ></button>
      </div>
    </header>
    <terminal
      :status="sessionStatus"
      :terminal-build-path="sessionPath"
    />
  </div>
</template>
