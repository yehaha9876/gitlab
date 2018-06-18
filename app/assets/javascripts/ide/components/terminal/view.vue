<script>
import { mapActions, mapGetters } from 'vuex';
import TerminalDetail from './detail.vue';
import axios from 'axios';

export default {
  components: {
    TerminalDetail
  },
  data: function() {
     return {
         runnerState: true,
     };
  },
  mounted() {
    this.initWebIDEPolling();
  },
  computed: {
    ...mapGetters(['currentProject']),
  },
  methods: {
    initWebIDEPolling() {
      debugger;
      // http://localhost:3001/api/v4/projects/34/pipelines?source=webide&scope=running
      this.runnerState = false;
    },
    startWebIDERunner() {
      this.runnerState = true;
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
