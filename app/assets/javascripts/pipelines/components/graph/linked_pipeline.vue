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
    graphPosition: {
      type: String,
      required: true,
    },
  },
  components: {
    ciStatus,
  },
  computed: {
    pipelineCss() {
      if (this.graphPosition === 'right') {
        return ``;
      } else {
        return ``;
      }
    },
  },
};

</script>

<template>
  <li class="linked-pipeline build"
      :class="pipelineCss"
    >
    <div class="curve"></div>
    <div>
      <a :href="pipelinePath" class="linked-pipeline-link">
        <span class="linked-pipeline-status ci-status-tex ci-status-textt">
          <ci-status :status="pipelineStatus"/>
        </span>
        <span class="linked-pipeline-project-name"> {{ projectName }}</span>
        <span class="linked-pipeline-id"> #{{ pipelineId }}</span>
      </a>
    </div>
  </li>
</template>
