<script>
import $ from 'jquery';
import { mapState } from 'vuex';
import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import Terminal from '~/terminal/terminal';
import ScrollButton from '~/ide/components/jobs/detail/scroll_button.vue';
import { STATUS_STARTING, STATUS_RUNNING, STATUS_STOPPING, STATUS_STOPPED } from '../../constants';

export default {
  components: {
    ScrollButton,
    GlLoadingIcon,
  },
  props: {
    terminalBuildPath: {
      type: String,
      required: false,
    },
    status: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      canScrollUp: false,
      canScrollDown: false,
    };
  },
  computed: {
    ...mapState(['panelResizing']),
    wsTerminalPath() {
      return this.terminalBuildPath && `${this.terminalBuildPath}`;
    },
    isStarting() {
      return this.status === STATUS_STARTING;
    },
    isRunning() {
      return this.status === STATUS_RUNNING;
    },
    isStopping() {
      return this.status === STATUS_STOPPING;
    },
    isStopped() {
      return this.status === STATUS_STOPPED;
    },
    loadingText() {
      if (this.isStarting) {
        return __('Starting...');
      } else if (this.isStopping) {
        return __('Stopping...');
      }

      return '';
    },
  },
  watch: {
    panelResizing() {
      if (!this.panelResizing) {
        this.resizeTerminal();
      }
    },
    status() {
      if (this.isRunning) {
        this.recreateTerminal();
      } else if (this.isStopping) {
        this.stopTerminal();
      }
    },
  },
  beforeDestroy() {
    this.destroyTerminal();
  },
  methods: {
    recreateTerminal() {
      this.destroyTerminal();
      this.terminal = new Terminal(this.$refs.terminal);

      $(this.$refs.terminal)
        .find('.xterm-viewport')
        .scroll(event => {
          this.onScrollUpdate(event.target);
        });
    },
    destroyTerminal() {
      if (this.terminal) {
        this.terminal.dispose();
        this.terminal = null;
      }
    },
    stopTerminal() {
      if (this.terminal) {
        this.terminal.stop();
      }
    },
    resizeTerminal() {
      $(window).trigger('resize.terminal');
    },
    scrollUp() {
      this.terminal.scrollToTop();
    },
    scrollDown() {
      this.terminal.scrollToBottom();
    },
    onScrollUpdate: _.throttle(function throttledOnScrollUpdate({
      scrollTop,
      offsetHeight,
      scrollHeight,
    }) {
      this.canScrollUp = scrollTop > 0;
      this.canScrollDown = scrollTop + offsetHeight < scrollHeight;
    }),
  },
};
</script>

<template>
  <div class="d-flex flex-column flex-fill min-height-0">
    <div class="top-bar d-flex border-left-0 align-items-center">
      <div>
        <template v-if="loadingText">
          <gl-loading-icon :inline="true" />
          <span v-text="loadingText"></span>
        </template>
      </div>
      <div class="controllers ml-auto">
        <scroll-button :disabled="!canScrollUp" direction="up" @click="scrollUp" />
        <scroll-button :disabled="!canScrollDown" direction="down" @click="scrollDown" />
      </div>
    </div>
    <div class="terminal-wrapper d-flex flex-fill min-height-0">
      <div
        ref="terminal"
        class="ide-terminal-trace flex-fill min-height-0 w-100"
        :data-project-path="wsTerminalPath"
      ></div>
    </div>
  </div>
</template>
