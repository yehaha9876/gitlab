<script>
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    CiIcon,
    CiBadge,
    Icon,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasUpstreamPipeline() {
      return this.project.upstream_pipeline_status !== null;
    },
    hasDownstreamPipelines() {
      return this.project.downstream_pipelines && this.project.downstream_pipelines.length > 0;
    },
    pipelineClasses() {
      return {
        'ops-dashboard-project-pipeline-failed': false,
      };
    },
  },
};
</script>

<template>
  <div :class="pipelineClasses" class="ops-dashboard-project-pipeline">
    <ci-icon v-if="hasUpstreamPipeline" :status="project.upstream_pipeline_status" />
    <icon name="arrow-right" />
    <ci-badge :status="project.pipeline_status" />
    <icon name="arrow-right" />
    <template v-if="hasDownstreamPipelines">
      <span v-for="pipeline in project.downstream_pipelines" :key="pipeline.id">
        <ci-icon :status="pipeline" />
      </span>
    </template>
  </div>
</template>
