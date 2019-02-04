<script>
import Container from '~/environments/components/container.vue';
import { mapState } from 'vuex';

export default {
  extends: Container,
  computed: {
    ...mapState([
      'canaryDeploymentFeatureId',
      'showCanaryDeploymentCallout',
      'userCalloutsPath',
      'lockPromotionSvgPath',
      'helpCanaryDeploymentsPath',
    ]),
  },
};
</script>
