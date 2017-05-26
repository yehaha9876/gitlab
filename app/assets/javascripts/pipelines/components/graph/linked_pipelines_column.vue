<script>
import linkedPipeline from './linked_pipeline.vue';

export default {
  props: {
    columnTitle: {
      type: String,
      required: true,
    },
    linkedPipelines: {
      type: Array,
      required: true,
    },
    graphPosition: {
      type: String,
      required: false,
    },
  },
  components: {
    linkedPipeline,
  },
  computed: {
    columnCss() {
      if (this.graphPosition === 'right') {
        return `graph-position-right column-margin-before`;
      } else {
        return `graph-position-left`;
      }
    },
  },
  methods: {
    maybeApplyFlatConnectorBefore(index, graphPosition) {
      if (index === 0 && graphPosition === 'right') {
        return 'flat-connector-before';
      }
      return '';
    },
  },
};
</script>

<template>
  <div
    class="stage-column linked-pipelines-column"
    :class="columnCss"
    >
    <div class="stage-name linked-pipelines-column-title"> {{ columnTitle }} </div>
    <ul>
      <linked-pipeline
        v-for="(pipeline, index) in linkedPipelines"
        :class="maybeApplyFlatConnectorBefore(index, graphPosition)"
        :key="pipeline.id"
        :pipeline-id="pipeline.id"
        :project-name="pipeline.project_name"
        :pipeline-status="pipeline.details.status"
        :pipeline-path="pipeline.path"
        :graph-position="graphPosition"
      />
    </ul>
  </div>
</template>
