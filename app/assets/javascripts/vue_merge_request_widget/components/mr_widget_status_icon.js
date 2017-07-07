import ciIcon from '../../vue_shared/components/ci_icon.vue';

export default {
  props: {
    status: { type: String, required: true },
  },
  components: {
    ciIcon,
  },
  computed: {
    statusObj() {
      return {
        group: this.status,
        icon: `icon_status_${this.status}`,
      };
    },
  },
  template: `
    <ci-icon :status="statusObj" />
  `,
};
