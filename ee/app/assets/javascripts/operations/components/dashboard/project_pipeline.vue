<script>
import { __, sprintf } from '~/locale';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import Icon from '~/vue_shared/components/icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import ProjectPipelineStatus from './project_pipeline_status.vue';

export default {
  components: {
    CiBadgeLink,
    Icon,
    ProjectPipelineStatus,
  },
  directives: {
    Tooltip,
  },
  props: {
    currentStatus: {
      type: Object,
      required: true,
    },
    upstreamPipeline: {
      type: Object,
      required: false,
      default: null,
    },
    downstreamPipelines: {
      type: Array,
      required: false,
      default: null,
    },
    hasPipelineFailed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    downstreamPipelinesHaveFailed() {
      return this.downstreamPipelines.some(pipeline => pipeline.details.status.group === 'failed');
    },
    pipelineClasses() {
      return {
        'ops-dashboard-project-pipeline-failed':
          this.hasPipelineFailed || this.downstreamPipelinesHaveFailed,
      };
    },
    hasDownstreamPipelines() {
      return this.downstreamPipelines && this.downstreamPipelines.length > 0;
    },
    hasExtraDownstream() {
      return this.downstreamCount > this.shownDownstreamCount;
    },
    shownDownstreamPipelines() {
      return this.downstreamPipelines.slice(0, 4);
    },
    shownDownstreamCount() {
      return this.shownDownstreamPipelines.length;
    },
    downstreamCount() {
      return this.downstreamPipelines.length;
    },
    extraDownstreamText() {
      return `+${this.downstreamCount - this.shownDownstreamCount}`;
    },
    extraDownstreamTitle() {
      const extra = this.downstreamCount - this.shownDownstreamCount;

      return sprintf('%{extra} more downstream pipelines', {
        extra,
      });
    },
    upstreamRelation() {
      return __('Upstream');
    },
    downstreamRelation() {
      return __('Downstream');
    },
  },
};
</script>
<template>
  <div :class="pipelineClasses" class="ops-dashboard-project-pipeline">
    <template v-if="upstreamPipeline">
      <project-pipeline-status
        :status="upstreamPipeline.details.status"
        :relation="upstreamRelation"
      />
      <icon name="arrow-right" class="ops-dashboard-project-pipeline-arrow mx-1" />
    </template>

    <ci-badge-link :status="currentStatus" :show-text="true" />

    <template v-if="hasDownstreamPipelines">
      <icon name="arrow-right" class="ops-dashboard-project-pipeline-arrow mx-1" />

      <span
        v-for="(pipeline, index) in shownDownstreamPipelines"
        :key="pipeline.id"
        :style="`z-index: ${shownDownstreamPipelines.length + 1 - index}`"
        class="ops-dashboard-project-pipeline-downstream"
      >
        <project-pipeline-status :status="pipeline.details.status" :relation="downstreamRelation" />
      </span>
      <a
        v-if="hasExtraDownstream"
        v-tooltip
        :href="currentStatus.details_path"
        :title="extraDownstreamTitle"
        class="ops-dashboard-project-pipeline-extra"
      >
        {{ extraDownstreamText }}
      </a>
    </template>
  </div>
</template>
