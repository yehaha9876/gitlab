<script>
import relatedProjectPipelineComponent from './linked_pipeline.vue';

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
  },
  components: {
    linkedPipeline,
  },
};
</script>

<template>
  <div class="stage-column linked-pipelines-column">
    <span class="stage-name linked-pipeline-title"> {{ columnTitle }} </span>
    <ul>
      <linked-pipeline
        v-for="(pipeline, index) in linkedPipelines"
        :pipeline-id="pipeline.id"
        :project-name="pipeline.project_name"
        :pipeline-status="pipeline.details.status"
        :pipeline-path="pipeline.path"
      />
    </ul>
    <span> arrow graphic </span>
  </div>
</template>
