<script>

import { mapState } from 'vuex';
import initTerminal from '~/terminal/';

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
      initTerminal();
    }
  },
  watch: {
    panelResizing() {
      if (!this.panelResizing) {
        $(window).trigger('resize.terminal');
      }
    },
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
  </div>
</template>
