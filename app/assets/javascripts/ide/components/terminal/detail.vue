<script>

import { mapState } from 'vuex';
import initTerminal from '~/terminal/';
import initSyncProxy from '~/sync_proxy'

export default {
  components: {},
  props: {
    terminalRunning: {
      type: Boolean,
      required: true,
    },
    terminalBuildPath: {
      type: String,
      required: true,
    },
    pendingBuild: {
      type: Boolean,
      required: true
    },
  },
  data() {
    return {
      terminal: null,
    }
  },
  computed: {
    ...mapState(['panelResizing']),
    wsTerminalPath() {
      if (this.terminalBuildPath === '') {
        return '';
      }

      return `${this.terminalBuildPath}/terminal.ws`;
    },
  },
  updated() {
    if (this.terminalRunning) {
      this.terminal = initTerminal();
      debugger
      initSyncProxy({url: this.wsTerminalPath});
    }
  },
  beforeDestroy() {
    this.destroyTerminal();
  },
  watch: {
    panelResizing() {
      if (!this.panelResizing) {
        $(window).trigger('resize.terminal');
      }
    },
  },
  methods: {
    destroyTerminal() {
      if (this.terminal) {
        this.terminal.destroyTerminal();
      }
    }
  },
};
</script>

<template>
  <div class="ide-terminal d-flex flex-column flex-fill">
    <template v-if="terminalRunning">
      <pre
        class="build-trace mb-0 h-100"
      >
        <div class="terminal-container">
          <div
            id="terminal"
            :data-project-path="wsTerminalPath">
          </div>
        </div>
      </pre>
    </template>
    <template v-if="pendingBuild">
      {{ __('Loading...') }}
    </template>
  </div>
</template>
