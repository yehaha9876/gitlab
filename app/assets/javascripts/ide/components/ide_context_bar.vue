<script>
  import { mapState, mapActions } from 'vuex';
  import repoCommitSection from './repo_commit_section.vue';
  import icon from '../../vue_shared/components/icon.vue';
  import panelResizer from '../../vue_shared/components/panel_resizer.vue';

  export default {
    components: {
      repoCommitSection,
      icon,
      panelResizer,
    },
    props: {
      noChangesStateSvgPath: {
        type: String,
        required: true,
      },
      committedStateSvgPath: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        width: 340,
      };
    },
    computed: {
      ...mapState([
        'rightPanelCollapsed',
      ]),
      maxSize() {
        return window.innerWidth / 2;
      },
      panelStyle() {
        if (!this.rightPanelCollapsed) {
          return { width: `${this.width}px` };
        }
        return {};
      },
    },
    methods: {
      ...mapActions([
        'toggleRightPanelCollapsed',
        'setResizingStatus',
      ]),

      toggleFullbarCollapsed() {
        if (this.rightPanelCollapsed) {
          this.toggleRightPanelCollapsed();
        }
      },
      resizingStarted() {
        this.setResizingStatus(true);
      },
      resizingEnded() {
        this.setResizingStatus(false);
      },
    },
  };
</script>

<template>
  <div
    class="multi-file-commit-panel"
    :class="{
      'is-collapsed': rightPanelCollapsed,
    }"
    :style="panelStyle"
    @click="toggleFullbarCollapsed"
  >
    <div
      class="multi-file-commit-panel-section"
    >
      <repo-commit-section
        :no-changes-state-svg-path="noChangesStateSvgPath"
        :committed-state-svg-path="committedStateSvgPath"
      />
    </div>
    <panel-resizer
      :size.sync="width"
      :enabled="!rightPanelCollapsed"
      :start-size="340"
      :min-size="200"
      :max-size="maxSize"
      @resize-start="resizingStarted"
      @resize-end="resizingEnded"
      side="left"
    />
  </div>
</template>
