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
      return `graph-position-${this.graphPosition}`;
    },
  },
  methods: {
    flatConnectorCss(index) {
      let className = '';

      if (index === 0 && this.graphPosition === 'right') {
        className += 'flat-connector-before';
      }

      return className;
    },
  },
};
</script>

<template>
  <div
    class="linked-pipelines-column"
    :class="columnCss"
    >
    <div class="stage-name linked-pipelines-column-title"> {{ columnTitle }} </div>
    <div class="triangle-pointer"></div>
    <ul>
      <linked-pipeline
        v-for="(pipeline, index) in linkedPipelines"
        :class="flatConnectorCss(index)"
        :key="pipeline.id"
        :pipeline-id="pipeline.id"
        :project-name="pipeline.project.name"
        :pipeline-status="pipeline.details.status"
        :pipeline-path="pipeline.path"
      />
    </ul>
  </div>
</template>
