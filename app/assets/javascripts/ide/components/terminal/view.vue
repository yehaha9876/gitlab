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
         runnerState: false
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
        this.fetchRunninWebIDEPipeline();
      }, 1000);
    },
    startWebIDERunner() {
      this.runnerState = true;
    },
    runningWebIDEPipeline(pipelines) {
      this.runnerState = (pipelines.count.running != "0")
    },
    fetchRunninWebIDEPipeline() {
      axios
        .get(`/${this.currentProject.path_with_namespace}/pipelines`, { params: { format: 'json', source: 'webide', scope: 'running' } })
        .then(response => (this.runningWebIDEPipeline(response.data)))
    },
    stopWebIDEPolling() {
      if (this.intervalId) {
        clearInterval(this.intervalId);
      }
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
          v-if="!runnerState"
          type="button"
          class="btn btn-default btn-sm"
          @click="startWebIDERunner"
        >
          {{ __('Start Web IDE runner') }}
        </button>
      </div>
    </header>
    <terminal-detail
      :loading="!runnerState"
    />
  </div>
</template>
