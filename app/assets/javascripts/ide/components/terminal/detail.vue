<script>

import initTerminal from '~/terminal/';

export default {
  components: {
  },
  props: {
    terminalRunning: {
      type: Boolean,
      required: true,
    },
    terminalBuildPath: {
      type: String,
      required: true,
    }
  },
  computed: {
    wsTerminalPath: function () {
      if (this.terminalBuildPath == '') {
        return '';
      } else {
        return `${this.terminalBuildPath}/terminal.ws`
      }
    },
  },
  updated: function () {
    if (this.terminalRunning) {
      initTerminal();
    }
  },
  // watch: {
  //   terminalRunning: function (val) {
  //     // if (val) {
  //     //   initTerminal();
  //     // }
  //   },
  // },
};
</script>

<template>
  <div class="ide-terminal build-page d-flex flex-column flex-fill">
    <template v-if="terminalRunning">
      <pre
        ref="buildTrace"
        class="build-trace mb-0 h-100"
      >
        <div class="container-fluid container-limited terminal-container">
          <div
            :data-project-path="wsTerminalPath"
            id="terminal">
          </div>
        </div>
      </pre>
    </template>
  </div>
</template>
