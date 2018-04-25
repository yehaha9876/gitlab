<script>
export default {
  props: {
    generatedLinePath: {
      type: String,
      required: true,
    },
    generatedAreaPath: {
      type: String,
      required: true,
    },
    lineStyle: {
      type: String,
      required: false,
      default: '',
    },
    lineColor: {
      type: String,
      required: true,
    },
    areaColor: {
      type: String,
      required: true,
    },
    currentCoordinates: {
      type: Object,
      required: false,
      default: () => ({ currentX: 0, currentY: 0 }),
    },
    showDot: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    strokeDashArray() {
      if (this.lineStyle === 'dashed') return '3, 1';
      if (this.lineStyle === 'dotted') return '1, 1';
      return null;
    },
  },
};
</script>
<template>
  <g>
    <circle
      class="circle-path"
      :cx="currentCoordinates.currentX - 5"
      :cy="currentCoordinates.currentY + 20"
      :fill="lineColor"
      :stroke="lineColor"
      r="3"
      v-if="showDot"
    />
    <path
      class="metric-area"
      :d="generatedAreaPath"
      :fill="areaColor"
      transform="translate(-5, 20)"
    />
    <path
      class="metric-line"
      :d="generatedLinePath"
      :stroke="lineColor"
      fill="none"
      stroke-width="1"
      :stroke-dasharray="strokeDashArray"
      transform="translate(-5, 20)"
    />
  </g>
</template>
