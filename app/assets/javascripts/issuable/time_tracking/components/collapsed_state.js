import stopwatchSvg from 'icons/_icon_stopwatch.svg';

import '../../../lib/utils/pretty_time';

export default {
  name: 'TimeTrackingCollapsedState',
  props: {
    showComparisonState: {
      type: Boolean,
      required: true,
    },
    showSpentOnlyState: {
      type: Boolean,
      required: true,
    },
    showEstimateOnlyState: {
      type: Boolean,
      required: true,
    },
    showNoTimeTrackingState: {
      type: Boolean,
      required: true,
    },
    timeSpentHumanReadable: {
      type: String,
      required: false,
    },
    timeEstimateHumanReadable: {
      type: String,
      required: false,
    },
  },
  computed: {
    abbreviateTimeEstimate() {
      return this.abbreviateTime(this.timeEstimateHumanReadable);
    },
    abbreviateTimeSpent() {
      return this.abbreviateTime(this.timeSpentHumanReadable);
    },
    comparisonState() {
      return `${this.abbreviateTimeSpent} / ${this.abbreviateTimeEstimate}`;
    },
    estimateOnlyState() {
      return `-- / ${this.abbreviateTimeEstimate}`;
    },
    spentOnlyState() {
      return `${this.abbreviateTimeSpent} / --`;
    },
  },
  methods: {
    abbreviateTime(timeStr) {
      return gl.utils.prettyTime.abbreviateTime(timeStr);
    },
  },
  template: `
    <div class="sidebar-collapsed-icon">
      ${stopwatchSvg}
      <div class="time-tracking-collapsed-summary">
        <div
          class="compare"
          v-if="showComparisonState"
        >
          <span>
            {{ comparisonState }}
          </span>
        </div>
        <div
          class="estimate-only"
          v-if="showEstimateOnlyState">
          <span class="bold">
            {{ estimateOnlyState }}
          </span>
        </div>
        <div
          class="spend-only"
          v-if="showSpentOnlyState">
          <span class="bold">
            {{ spentOnlyState }}
          </span>
        </div>
        <div
          class="no-tracking"
          v-if="showNoTimeTrackingState">
          <span class="no-value">
            None
          </span>
        </div>
      </div>
    </div>
  `,
};
