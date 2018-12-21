<script>
import { GlLoadingIcon, GlTooltipDirective, GlButton } from '@gitlab/ui';
import CiStatus from '~/vue_shared/components/ci_icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiStatus,
    GlLoadingIcon,
    GlButton,
    PipelineGraph: () => import('~/pipelines/components/graph/graph_component.vue')
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    pipelineStatus() {
      return this.pipeline.details.status
    },
    projectName() {
      return this.pipeline.project.name;
    },
    tooltipText() {
      return `${this.projectName} - ${this.pipelineStatus.label}`;
    },
    buttonId() {
      return `js-linked-pipeline-${this.pipeline.id}`;
    },
  },
  methods: {
    onClickLinkedPipeline() {
      this.$root.$emit('bv::hide::tooltip', this.buttonId);
      this.$emit('pipelineClicked');
    },
  },
};
</script>

<template>
  <li class="linked-pipeline build">
    <div class="curve"></div>
    <gl-button
      :id="buttonId"
      v-gl-tooltip
      :title="tooltipText"
      class="js-linked-pipeline-content linked-pipeline-content"
      @click="onClickLinkedPipeline"
    >
      <gl-loading-icon v-if="isLoading" class="js-linked-pipeline-loading d-inline" />
      <ci-status v-else :status="pipelineStatus" class="js-linked-pipeline-status" />

      <span class="str-truncated align-bottom"> {{ projectName }} &#8226; #{{ pipelineId }} </span>
    </gl-button>
    <pipeline-graph
      v-if="!pipeline.isCollapsed"
      :pipeline="pipeline.details"
    />
  </li>
</template>
