<script>
// TODO move this file to ee
// TODO change name to something like 'canary_deployment_callout'
// TODO figure out how to add "canary_deployment" to possible feature IDs
import lockPromotionIllustration from '@gitlab/svgs/dist/illustrations/lock_promotion.svg';
import Icon from '~/vue_shared/components/icon.vue';
import PersistentUserCallout from '~/persistent_user_callout';

export default {
  components: {
    Icon,
  },
  props: {
    canaryDeploymentFeatureId: {
      type: String,
      required: true,
    },
    userCalloutsPath: {
      type: String,
      required: true,
    },
  },
  mounted() {
    // TODO change class names to 'canary-deployment-callout`
    const callout = document.querySelector('.environments-canary-promo');

    if (callout) new PersistentUserCallout(callout); // eslint-disable-line no-new
  },
  computed: {
    lockPromotionIllustration() {
      return lockPromotionIllustration;
    },
  },
};
</script>

<template>
  <div
    class="d-flex p-3 environments-canary-promo"
    :data-dismiss-endpoint="userCalloutsPath"
    :data-feature-id="canaryDeploymentFeatureId"
  >
    <div
      class="svg-container pr-3"
      v-html="lockPromotionIllustration"
    />

    <div class="pl-3">
      <p class="font-weight-bold mb-1">
        Upgrade plan to unlock Canary Development feature
      </p>

      <p class="environments-canary-promo-message">
        Canary Development is a popular CI strategy, where a small portion of the fleet is
        updated to the new version of your application.
        <a href="https://docs.gitlab.com/ee/user/project/canary_deployments.html">
          Read more
        </a>
      </p>

      <a href="https://about.gitlab.com/sales/" class="btn btn-outline-primary">
        Contact sales to upgrade
      </a>
    </div>

    <div class="ml-auto pr-2 environments-canary-promo-close js-close"> 
      <icon name="close" />
    </div>
  </div>
</template>
