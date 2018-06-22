<script>
import { mapGetters } from 'vuex';
import axios from 'axios';
import TerminalDetail from './detail.vue';

export default {
  components: {
    TerminalDetail,
  },
  data() {
    return {
      terminalRunning: false,
      terminalBuildPath: '',
    };
  },
  computed: {
    ...mapGetters(['currentProject']),
  },
  mounted() {
    this.initWebIDEPolling();
  },
  beforeDestroy() {
    this.stopWebIDEPolling();
  },
  methods: {
    initWebIDEPolling() {
      this.intervalId = setInterval(() => {
        this.fetchRunningWebIDEPipeline();
      }, 1000);
    },
    startWebIDERunner() {
      if (!this.terminalRunning) {
        axios
          .post(`/${this.currentProject.path_with_namespace}/-/jobs/create_web_ide_terminal`, { params: { format: 'json' } })
          .then(response => (this.setTerminalBuildPath(response.data.details_path)));
      }
    },
    runningWebIDEPipeline(job) {
      this.terminalRunning = job !== null;

      if (this.terminalRunning) {
        this.setTerminalBuildPath(job.details_path);
      }
    },
    fetchRunningWebIDEPipeline() {
      axios
        .get(`/${this.currentProject.path_with_namespace}/-/jobs/web_ide_terminal`, { params: { format: 'json' } })
        .then(response => (this.runningWebIDEPipeline(response.data)));
    },
    stopWebIDEPolling() {
      if (this.intervalId) {
        clearInterval(this.intervalId);
      }
    },
    setTerminalBuildPath(val) {
      this.terminalBuildPath = val;
    },
  },
};
</script>

<template>
  <div class="ide-terminal build-page d-flex flex-column flex-fill">
    <header
      class="ide-tree-header"
    >
      <span>
        <strong>
          {{ __('Terminal') }}
        </strong>
      </span>
      <div class="ml-auto align-self-center">
        <button
          v-if="!terminalRunning"
          type="button"
          class="btn btn-default btn-sm"
          @click="startWebIDERunner"
        >
          {{ __('Start Web IDE runner') }}
        </button>
      </div>
    </header>
    <terminal-detail
      :terminal-running="terminalRunning"
      :terminal-build-path="terminalBuildPath"
    />
  </div>
</template>
