<script>
  /* global Flash */
  import linkedPipelinesColumn from './linked_pipelines_column.vue';
  import stageColumnComponent from './stage_column_component.vue';
  import loadingIcon from '../../../vue_shared/components/loading_icon.vue';
  import '../../../flash';

  export default {
    components: {
      linkedPipelinesColumn,
      stageColumnComponent,
      loadingIcon,
    },
    props: {
      state: {
        type: Object,
        required: true,
      },
    },
    computed: {
      isLoading() {
        return !this.state.graph.length;
      },
      hasTriggered() {
        return !!this.state.triggered.length;
      },
      hasTriggerer() {
        return !!this.state.triggerer.length;
      },
      linkedPipelinesClass() {
        return this.hasTriggered || this.hasTriggerer ? 'has-linked-pipelines' : '';
      },
    },
    methods: {
      capitalizeStageName(name) {
        return name.charAt(0).toUpperCase() + name.slice(1);
      },

      isFirstColumn(index) {
        return index === 0;
      },

      stageConnectorClass(index, stage) {
        let className;

        // If it's the first stage column and only has one job
        if (index === 0 && stage.groups.length === 1) {
          if (!this.hasTriggerer) {
            className = 'no-margin';
          } else {
            className = 'left-margin';
          }
        } else if (index > 0) {
          // If it is not the first column
          className = 'left-margin';
        }

        return className;
      },
      linkedPipelineClass(index) {
        let className = '';
        const isFirstStage = index === 0;
        const isLastStage = index === this.state.graph.length - 1;

        if (isFirstStage && this.hasTriggerer) {
          className += 'has-upstream';
        } else if (isLastStage && this.hasTriggered) {
          className += 'has-downstream';
        }

        return className;
      },
    },
  };
</script>
<template>
  <div class="build-content middle-block js-pipeline-graph">
    <div class="pipeline-visualization pipeline-graph">
      <div class="text-center">
        <loading-icon
          v-if="isLoading"
          size="3"
          />
      </div>

      <linked-pipelines-column
        v-if="hasTriggerer"
        :linked-pipelines="state.triggerer"
        column-title="Upstream"
        graph-position="left"
      />

      <ul
        v-if="!isLoading"
        class="stage-column-list"
        :class="linkedPipelinesClass">
        <stage-column-component
          v-for="(stage, index) in state.graph"
          :class="linkedPipelineClass(index)"
          :title="capitalizeStageName(stage.name)"
          :jobs="stage.groups"
          :key="stage.name"
          :stage-connector-class="stageConnectorClass(index, stage)"
          :is-first-column="isFirstColumn(index)"
          :has-triggerer="hasTriggerer"
          />
      </ul>

      <linked-pipelines-column
        v-if="hasTriggered"
        :linked-pipelines="state.triggered"
        column-title="Downstream"
        graph-position="right"
      />
    </div>
  </div>
</template>
