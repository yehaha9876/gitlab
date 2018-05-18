<script>
import { scaleLinear, scaleBand } from 'd3-scale';
import { axisBottom, axisLeft } from 'd3-axis';
import { select } from 'd3-selection';
import { max } from 'd3-array';
import bp from '~/breakpoints';

const d3 = { axisBottom, axisLeft, select, scaleLinear, scaleBand, max };

export default {
  props: {
    graphData: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      baseGraphHeight: 450,
      baseGraphWidth: 600,
      graphHeight: 450,
      graphWidth: 600,
      realPixelRatio: 1,
    };
  },
  computed: {
    outerViewBox() {
      return `0 0 ${this.baseGraphWidth} ${this.baseGraphHeight}`;
    },
    paddingBottomRootSvg() {
      return {
        paddingBottom: `${Math.ceil(this.baseGraphHeight * 100) / this.baseGraphWidth || 0}%`,
      };
    },
  },
  mounted() {
    this.draw();
  },
  methods: {
    draw() {
      const breakpointSize = bp.getBreakpointSize();

      if (breakpointSize === 'xs' || breakpointSize === 'sm') {
        this.graphHeight = 300;
      }

      this.graphWidth = this.$refs.baseSvg.clientWidth - 20; // divide this by half (right and left margins);
      this.graphHeight = this.graphHeight - 20; // divide by half, top and bottom;
      this.baseGraphHeight = this.graphHeight - 50;
      this.baseGraphWidth = this.graphWidth;
      this.realPixelRatio = this.$refs.baseSvg.clientWidth / this.baseGraphWidth;

      this.renderAxes();
    },

    renderAxes() {
      const axisXScale = d3.scaleBand().range([0, this.graphWidth]);
      const axisYScale = d3.scaleLinear().range([this.graphHeight, 0]);

      axisXScale.domain(this.graphData.map((d) => d.name));
      axisYScale.domain([0, d3.max(this.graphData.map(d => d.value))]);

      const xAxis = d3
        .axisBottom()
        .scale(axisXScale);

      const yAxis = d3
        .axisLeft()
        .scale(axisYScale);

      d3
        .select(this.$refs.baseSvg)
        .select('.x-axis')
        .call(xAxis);
    },
  },
};
</script>
<template>
  <div class="bar-chart-graph">
    <div
      class="svg-container"
      :style="paddingBottomRootSvg">
      <svg
        :viewBox="outerViewBox"
        ref="baseSvg"
      >
        <g class="x-axis" />
        <g class="y-axis" />
        <rect
          x="10"
          y="10"
          width="5"
          height="30"
          fill="#e67664"
        />
      </svg>
    </div>
  </div>
</template>
<style>
  .bar-chart-graph {
    flex: 1 0 auto;
    min-width: 450px;
    padding: 16px / 2; /* $gl-padding / 2 */
  }

  .svg-container {
    position: relative;
    height: 0;
    width: 100%;
    padding: 0;
    padding-bottom: 100%;
  }
</style>
