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
      axios({
        method: $('#request_method').val(),
        url: this.session.proxyPath,
        params: {
          requested_uri: $("input.requesteduri").val(),
        }
      });
    },
    testws() {
      axios.get(this.session.proxy.replace("retry", "serviceaws"))
      // new WebSocket($('#wssurl').val());
    }
  },
};
</script>

<template>
  <div v-if="session" class="ide-terminal build-page d-flex flex-column">
    <header class="ide-job-header d-flex align-items-center">
      <h5>{{ __('Web Terminal') }}</h5>
      <div class="ml-auto align-self-center">
        <select
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
    <div v-if="session.status == 'running'">
      <input class="requesteduri" id="requesteduri"></input>
      <select id="request_method">
        <option value="get">
          GET
        </option>
        <option value="post">
          POST
        </option>
        <option value="put">
          PUT
        </option>
        <option value="delete">
          DELETE
        </option>
      </select>
      <button @click="test">
        Test
      </button>
    </div>
    <div v-if="session.status == 'running'">
      <input id="wssurl"></input>
      <button @click="testws">
        TestWSS
      </button>
    </div>
    <terminal :terminal-path="session.terminalPath" :status="session.status" />
  </div>
</template>
