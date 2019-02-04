<script>
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import { __ } from '~/locale';
import ProjectPipelineStatus from './project_pipeline_status.vue';

export default {
  components: {
    CiIcon,
    Icon,
    ProjectPipelineStatus,
  },
  directives: {
    Tooltip,
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
    shownDownstreamPipelines() {
      return this.project.downstream_pipelines.slice(0, 18);
    },
    shownDownstreamCount() {
      return this.shownDownstreamPipelines.length;
    },
    downstreamCount() {
      return this.project.downstream_pipelines.length;
    },
    moreDownstreamText() {
      return `+${this.downstreamCount - this.shownDownstreamCount}`;
    },
    extraDownstreamTitle() {
      const extra = this.downstreamCount - this.shownDownstreamCount;

      return `${extra} more downstream pipelines`;
    },
    upstreamRelation() {
      return __('Upstream');
    },
    currentRelation() {
      return __('Current project');
    },
    downstreamRelation() {
      return __('Downstream');
    },
  },
};
</script>

<template>
  <div :class="pipelineClasses" class="ops-dashboard-project-pipeline">
    <template v-if="hasUpstreamPipeline">
      <project-pipeline-status
        :status="project.upstream_pipeline_status"
        :relation="upstreamRelation"
      />
      <icon name="arrow-right" class="ops-dashboard-project-pipeline-arrow mx-1" />
    </template>

    <project-pipeline-status :status="project.pipeline_status" :relation="currentRelation" />

    <template v-if="hasDownstreamPipelines">
      <icon name="arrow-right" class="ops-dashboard-project-pipeline-arrow mx-1" />
      <span
        v-for="(pipeline, index) in shownDownstreamPipelines"
        :key="pipeline.id"
        :style="`z-index: ${shownDownstreamPipelines.length - index}`"
        class="ops-dashboard-project-pipeline-downstream"
      >
        <project-pipeline-status :status="pipeline" :relation="downstreamRelation" />
      </span>
      <a
        v-if="downstreamCount > shownDownstreamCount"
        v-tooltip
        :href="project.pipeline_status.details_path"
        :title="extraDownstreamTitle"
      >
        . . .
      </a>
    </template>
  </div>
</template>
