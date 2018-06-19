<script>
import { mapActions, mapGetters, dispatch } from 'vuex';
import TerminalDetail from './detail.vue';
import axios from 'axios';

export default {
  components: {
    TerminalDetail
  },
  data: function() {
     return {
         terminalRunning: false,
         terminalBuildPath: 'fran',
     };
  },
  mounted() {
    this.initWebIDEPolling();
  },
  beforeDestroy() {
    this.stopWebIDEPolling();
  },
  computed: {
    ...mapGetters(['currentProject']),
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
          .then(response => (this.setTerminalBuildPath(response.data.details_path)))
      }
    },
    runningWebIDEPipeline(pipelines) {
      // TODO: Fix this check
      this.terminalRunning = (pipelines.count.running != "0")
    },
    fetchRunningWebIDEPipeline() {
      axios
        .get(`/${this.currentProject.path_with_namespace}/pipelines`, { params: { format: 'json', source: 'webide', scope: 'running' } })
        .then(response => (this.runningWebIDEPipeline(response.data)))
    },
    stopWebIDEPolling() {
      if (this.intervalId) {
        clearInterval(this.intervalId);
      }
    },
    setTerminalBuildPath(val) {
      this.terminalBuildPath = val;
    }
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
      :terminalRunning="terminalRunning"
      :terminalBuildPath="terminalBuildPath"
    />
  </div>
</template>
