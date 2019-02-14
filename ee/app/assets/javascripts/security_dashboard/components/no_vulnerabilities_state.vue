<script>
import { GlEmptyState } from '@gitlab/ui';

export default {
  name: 'NoVulnerabilitiesState',
  components: { GlEmptyState },
  props: {
    svgPath: {
      type: String,
      required: true,
    },
    link: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-empty-state
    :svg-path="svgPath"
    :title="s__('Security Reports|We\'ve found no vulnerabilities for your group')"
    :description="
      s__(
        'Security Reports|While it\'s rare to have no vulnerabilities for your group, it can happen. In any event, we ask that you please double check your settings to make sure you\'ve set up your dashboard correctly.',
      )
    "
    :primary-button-link="link"
    :primary-button-text="s__('Security Reports|Learn more about setting up your dashboard')"
  />
</template>
