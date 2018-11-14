<script>
import lockPromotionIllustration from '@gitlab/svgs/dist/illustrations/lock_promotion.svg';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  computed: {
    lockPromotionIllustration() {
      return lockPromotionIllustration;
    },
  },
}
</script>

<template>
  <!-- TODO: check the bottom border color to make sure it matches-->
  <div class="d-flex p-3 border-bottom">
    <div
      class="svg-container pr-3"
      v-html="lockPromotionIllustration"
    />

    <div class="pl-3">
      <p class="font-weight-bold mb-1">
        Upgrade plan to unlock Canary Development feature
      </p>
      <!-- TODO: Adjust width to match design -->
      <p class="w-75">
        Canary Deveopment is a popular CI strategy, where a small portion of the fleet is
        updated to the new version of your application.
        <a href="https://docs.gitlab.com/ee/user/project/canary_deployments.html">
          Read more
        </a>
      </p>
      <!-- TODO: Adjust style to match design -->
      <a href="https://about.gitlab.com/sales/" class="btn btn-outline-primary">
        Contact sales to upgrade
      </a>
    </div>

    <!-- TODO: Handle click -->
    <!-- TODO: Adjust style to match design -->
    <div class="ml-auto pr-2"> 
      <icon name="close" />
    </div>
  </div>
</template>