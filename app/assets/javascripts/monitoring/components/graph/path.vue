<script>
import eventHub from '../../event_hub';

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
      default: () => {},
    },
    currentTimeSeriesIndex: {
      type: Number,
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
  methods: {
    areaHovered(e) {
      eventHub.$emit('areaHovered', {
        event: e,
        timeSeriesIndex: this.currentTimeSeriesIndex,
      });
    },
  },
};
</script>
<template>
  <g>
    <circle
      class="circle-path"
      :cx="currentCoordinates.currentX - 5"
      :cy="currentCoordinates.currentY + 19"
      :fill="lineColor"
      r="3"
      v-if="currentCoordinates"
    />
    <path
      class="metric-area"
      :d="generatedAreaPath"
      :fill="areaColor"
      transform="translate(-5, 20)"
      @mousemove="areaHovered($event)"
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
