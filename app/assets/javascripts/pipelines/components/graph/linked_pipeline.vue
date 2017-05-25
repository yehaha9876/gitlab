<script>
import ciStatus from '../../../vue_shared/components/ci_icon.vue';

export default {
  props: {
    pipelineId: {
      type: Number,
      required: true,
    },
    pipelinePath: {
      type: String,
      required: true,
    },
    pipelineStatus: {
      type: Object,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
  },
  components: {
    ciStatus,
  },
};

</script>

<template>
  <li class="build linked-pipeline">
    <a :href="pipelinePath" class="build-content linked-pipeline-link">
      <span class="linked-pipeline-status">
        <ci-status :status="pipelineStatus"/>
      </span>
      <span class="linked-pipeline-project-name"> {{ projectName }}</span>
      <span class="linked-pipeline-id"> #{{ pipelineId }}</span>
    </a>
  </li>
</template>
