export default {
  name: 'IssueCardUserCounter',
  props: {
    count: { type: Number, required: true },
  },
  computed: {
    tooltipTitle() {
      return `+${this.count} more assignees`
    },
    text() {
      if(this.count < 99) {
        return `+${this.count}`;
      } else {
        return '99+';
      }
    },
    wideCounter() {
      return this.count >= 99;
    },
  },
  template: `
    <span
      class="avatar-counter has-tooltip"
      :class="{ 'wide-counter': wideCounter }"
      data-container="body"
      data-placement="bottom"
      data-line-type="old"
      :data-original-title="tooltipTitle">
      {{ text }}
    </span>
  `,
};