<script>
import EnvironmentsApp from '~/environments/components/environments_app.vue';
import eventHub from '~/environments/event_hub';

export default {
  extends: EnvironmentsApp,
  created() {
    eventHub.$on('toggleDeployBoard', this.toggleDeployBoard);
  },
  beforeDestroy() {
    eventHub.$off('toggleDeployBoard');
  },
  methods: {
    /**
     * Toggles the visibility of the deploy boards of the clicked environment.
     * @param {Object} model
     */
    toggleDeployBoard(model) {
      this.store.toggleDeployBoard(model.id);
    },
  },
};
</script>
