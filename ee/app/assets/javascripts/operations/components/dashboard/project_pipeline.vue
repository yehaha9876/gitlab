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
    hasPipelineFailed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasUpstreamPipeline() {
      return (
        this.project.upstream_pipeline_status && this.project.upstream_pipeline_status !== null
      );
    },
    hasDownstreamPipelines() {
      return this.project.downstream_pipelines && this.project.downstream_pipelines.length > 0;
    },
    downstreamPipelinesHaveFailed() {
      return this.project.downstream_pipelines.some(status => status.group === 'failed');
    },
    pipelineClasses() {
      return {
        'ops-dashboard-project-pipeline-failed':
          this.hasPipelineFailed || this.downstreamPipelinesHaveFailed,
      };
    },
  },
};
</script>

<template>
  <div :class="pipelineClasses" class="ops-dashboard-project-pipeline">
    <template v-if="hasUpstreamPipeline">
      <ci-icon :status="project.upstream_pipeline_status" />
      <icon name="arrow-right" />
    </template>
    <ci-badge :status="project.pipeline_status" />
    <template v-if="hasDownstreamPipelines">
      <icon name="arrow-right" />
      <span v-for="pipeline in project.downstream_pipelines" :key="pipeline.id">
        <ci-icon :status="pipeline" />
      </span>
    </template>
  </div>
</template>
