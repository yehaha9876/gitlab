<script>
import { mapGetters, mapState } from 'vuex';
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
      pendingBuild: false,
      availableWebIdeRunners: false,
      validConfig: false,
    };
  },
  computed: {
    ...mapGetters(['currentProject']),
    ...mapState(['currentBranchId', 'webIdeJobTag']),
  },
  mounted() {
    this.initRunnerPolling();
    this.checkValidConfig();
  },
  beforeDestroy() {
    this.stopRunnerPolling();
    this.stopTerminalPolling();
  },
  methods: {
    checkAvailableWebIdeRunners() {
      axios
      .get(`/api/v4/projects/${this.currentProject.id}/runners`, { params: { scope: 'active', tag_list: this.webIdeJobTag } })
      .then(response => {
        this.availableWebIdeRunners = response.data.length !== 0;

        if (this.terminalRunning && this.availableWebIdeRunners == 0) {
          this.stopTerminalPolling();
          this.destroyTerminal();
        }
      });
    },
    initRunnerPolling() {
      this.intervalRunnerId = setInterval(() => {
        this.checkAvailableWebIdeRunners();
      }, 1000);
    },
    startTerminal() {
      if (!this.terminalRunning) {
        axios
          .post(`/${this.currentProject.path_with_namespace}/-/jobs/create_webide_terminal`, { branch: this.currentBranchId, format: 'json' })
          .then(response => {
            this.setTerminalBuildData(response.data)
            this.startTerminalPolling(5000);
          })
          .catch(error => {
            console.log(error.response.data)
          });
      }
    },
    stopTerminal() {
      if (this.terminalRunning || this.pendingBuild) {
        axios
          .post(`${this.terminalBuildPath}/cancel`)
          .then(response => (this.destroyTerminal()))
          .catch(error => {
            console.log(error.response.data)
          });
      }
    },
    restartTerminal() {
      if (!this.terminalRunning) {
        axios
          .post(`${this.terminalBuildPath}/retry`, { branch: this.currentBranchId, format: 'json' })
          .then(response => {
            this.setTerminalBuildData(response.data)
            this.startTerminalPolling(5000);
          })
          .catch(error => {
            // We may have removed the build, in this case
            // we'll just create a new pipeline
            if (error.response.status == 404) {
              this.startTerminal();
            }else{
              this.destroyTerminal()
            }
          });
      }
    },
    runningTerminalBuild(job) {
      if (job !== null) {
        this.terminalRunning = job.status.text === 'running';
        this.pendingBuild = job.status.text === 'pending'

        if (!this.terminalRunning && !this.pendingBuild) {
          this.stopTerminalPolling();
          this.destroyTerminal();
        }
      }else{
        //Handle if the terminal is running and the build has stopped
        this.destroyTerminal();
      }
    },
    fetchRunningTerminal() {
      axios
        .get(`${this.terminalBuildPath}`)
        .then(response => (this.runningTerminalBuild(response.data)))
        .catch(error => (console.log(error.response)));
    },
    stopRunnerPolling() {
      if (this.intervalRunnerId) {
        clearInterval(this.intervalRunnerId);
      }
    },
    stopTerminalPolling() {
      if (this.intervalTerminalId) {
        clearInterval(this.intervalTerminalId);
      }
    },
    startTerminalPolling(interval){
      this.stopTerminalPolling();

      this.intervalTerminalId = setInterval(() => {
        this.fetchRunningTerminal();
      }, interval);
    },
    setTerminalBuildData(data) {
      this.terminalBuildPath = data.details_path;
    },
    destroyTerminal() {
      if (this.terminalRunning) {
        this.terminalRunning = false;
        this.stopTerminalPolling();
      }
    },
    checkValidConfig() {
      axios
        .get(`/${this.currentProject.path_with_namespace}/-/jobs/check_config`, { params: { branch: this.currentBranchId, format: 'json' }})
        .then(response => {
          this.validConfig = true;
        })
        .catch(error => {
          this.validConfig = false;
        });
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
      <div v-if="availableWebIdeRunners && validConfig" class="ml-auto align-self-center">
        <button
          v-if="terminalRunning || pendingBuild"
          type="button"
          class="btn btn-default btn-sm"
          @click="stopTerminal"
        >
          {{ __('Stop Console') }}
        </button>
        <button
          v-if="!terminalRunning && !pendingBuild && terminalBuildPath"
          type="button"
          class="btn btn-default btn-sm"
          @click="restartTerminal"
        >
          {{ __('Restart Console') }}
        </button>
        <button
          v-if="!terminalRunning && !pendingBuild && !terminalBuildPath"
          type="button"
          class="btn btn-default btn-sm"
          @click="startTerminal"
        >
          {{ __('Start Console') }}
        </button>
      </div>
    </header>
    <terminal-detail
      v-if="availableWebIdeRunners && validConfig"
      :terminal-running="terminalRunning"
      :terminal-build-path="terminalBuildPath"
      :pending-build="pendingBuild"
    />
    <div v-else-if="!availableWebIdeRunners">
      No avilable web ide runners
    </div>
    <div v-else-if="!validConfig">
      No valid config
    </div>
  </div>
</template>
