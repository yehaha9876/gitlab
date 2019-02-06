<script>
import { __, sprintf } from '~/locale';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';

export default {
  components: {
    CiBadgeLink,
    CiIcon,
    Icon,
  },
  directives: {
    Tooltip,
  },
  props: {
    status: {
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
  relations: {
    current: __('Current Project'),
    downstream: __('Downstream'),
    upstream: __('Upstream'),
  },
  computed: {
    downstreamPipelinesHaveFailed() {
      return (
        this.downstreamPipelines &&
        this.downstreamPipelines.some(pipeline => pipeline.details.status.group === 'failed')
      );
    },
    pipelineClasses() {
      const hasFailures = this.hasPipelineFailed || this.downstreamPipelinesHaveFailed;
      return {
        'ops-dashboard-project-pipeline-failed': hasFailures,
        'bg-light': !hasFailures,
      };
    },
    hasDownstreamPipelines() {
      return this.downstreamPipelines && this.downstreamPipelines.length > 0;
    },
    hasExtraDownstream() {
      return this.downstreamCount > this.shownDownstreamCount;
    },
    shownDownstreamPipelines() {
      // We can only fit 14 statuses in the pipeline section before we have to truncate
      return this.downstreamPipelines.slice(0, 14);
    },
    shownDownstreamCount() {
      return this.shownDownstreamPipelines.length;
    },
    downstreamCount() {
      return this.downstreamPipelines.length;
    },
    extraDownstreamText() {
      const extra = this.downstreamCount - this.shownDownstreamCount;
      // Only render a plus sign if extra is a single digit
      const plus = extra < 10 ? '+' : '';
      return `${plus}${extra}`;
    },
    extraDownstreamTitle() {
      const extra = this.downstreamCount - this.shownDownstreamCount;

      return sprintf('%{extra} more downstream pipelines', {
        extra,
      });
    },
  },
};
</script>
<template>
  <div :class="pipelineClasses" class="ops-dashboard-project-pipeline py-1 px-2 mt-3">
    <template v-if="upstreamPipeline">
      <a
        v-tooltip
        :href="upstreamPipeline.details.status.details_path"
        :title="
          `<span class='bold'>${$options.relations.upstream}</span><br/><span>${
            upstreamPipeline.details.status.tooltip
          }</span><br/><span class='text-tertiary'>${upstreamPipeline.details.name_with_namespace ||
            ''}</span>`
        "
        data-html="true"
        class="d-inline-block align-middle"
      >
        <ci-icon
          class="d-flex js-upstream-pipeline-status"
          :status="upstreamPipeline.details.status"
        />
      </a>
      <icon name="arrow-right" class="ops-dashboard-project-pipeline-arrow align-middle mx-1" />
    </template>

    <span
      v-tooltip
      data-html="true"
      :title="
        `<span class='bold'>${$options.relations.current}</span><br/><span>${status.tooltip}</span>`
      "
    >
      <ci-badge-link class="bg-white" :status="status" :show-text="true" />
    </span>

    <template v-if="hasDownstreamPipelines">
      <icon name="arrow-right" class="ops-dashboard-project-pipeline-arrow align-middle mx-1" />

      <span
        v-for="(pipeline, index) in shownDownstreamPipelines"
        :key="pipeline.id"
        :style="`z-index: ${shownDownstreamPipelines.length + 1 - index}`"
        class="ops-dashboard-project-pipeline-downstream position-relative"
      >
        <a
          v-tooltip
          :href="pipeline.details.status.details_path"
          :title="
            `<span class='bold'>${$options.relations.downstream}</span><br/><span>${
              pipeline.details.status.tooltip
            }</span><br/><span class='text-tertiary'>${pipeline.details.name_with_namespace ||
              ''}</span>`
          "
          data-html="true"
          class="d-inline-block align-middle"
        >
          <ci-icon class="d-flex js-downstream-pipeline-status" :status="pipeline.details.status" />
        </a>
      </span>
      <a
        v-if="hasExtraDownstream"
        v-tooltip
        :href="status.details_path"
        :title="extraDownstreamTitle"
        class="ops-dashboard-project-pipeline-extra rounded-circle d-inline-block bold align-middle text-white text-center js-downstream-extra-icon"
      >
        {{ extraDownstreamText }}
      </a>
    </template>
  </div>
</template>
