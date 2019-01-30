<script>
import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import Terminal from './terminal.vue';
import { isEndingStatus } from '../../utils';

export default {
  components: {
    Terminal,
  },
  computed: {
    ...mapState('terminal', ['session']),
    actionButton() {
      if (isEndingStatus(this.session.status)) {
        return {
          action: () => this.restartSession(),
          text: __('Restart Terminal'),
          class: 'btn-primary',
        };
      }

      return {
        action: () => this.stopSession(),
        text: __('Stop Terminal'),
        class: 'btn-inverted btn-remove',
      };
    },
  },
  methods: {
    ...mapActions('terminal', ['restartSession', 'stopSession']),
    test() {
      axios.get(this.session.retryPath.replace("retry", "service"), { params: { requested_uri: $("input.requesteduri").val() }});
    }
  },
};
</script>

<template>
  <div v-if="session" class="ide-terminal build-page d-flex flex-column">
    <header class="ide-job-header d-flex align-items-center">
      <h5>{{ __('Web Terminal') }}</h5>
      <div class="ml-auto align-self-center">
        <input class="requesteduri" id="requesteduri" v-if="session.status == 'running'"></input>
        <button @click="test" v-if="session.status == 'running'">
          Test
        </button>
        <button
          v-if="actionButton"
          type="button"
          class="btn btn-sm"
          :class="actionButton.class"
          @click="actionButton.action"
        >
          {{ actionButton.text }}
        </button>
      </div>
    </header>
    <terminal :terminal-path="session.terminalPath" :status="session.status" />
  </div>
</template>
