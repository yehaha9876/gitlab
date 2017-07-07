import ciIcon from '../../vue_shared/components/ci_icon.vue';

export default {
  props: {
    status: { type: String, required: true },
  },
  components: {
    ciIcon,
  },
  template: `
    <ci-icon :status="{ group: status, icon: 'icon_status_' + status }" />
  `,
};
