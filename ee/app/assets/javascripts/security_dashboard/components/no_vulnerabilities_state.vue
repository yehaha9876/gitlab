<script>
import EmptyState from './empty_state.vue';

export default {
  name: 'NoVulnerabilitiesState',
  components: { EmptyState },
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
  <EmptyState
    :svg-path="svgPath"
    :svg-alt="s__('Security Reports|No Vulnerabilities')"
    :heading="s__('Security Reports|We\'ve found no vulnerabilities for your group')"
    :message="
      s__(
        'Security Reports|While it\'s rare to have no vulnerabilities for your group, it can happen. In any event, we ask that you please double check your settings to make sure you\'ve set up your dashboard correctly.',
      )
    "
    :link="link"
    :link-text="s__('Security Reports|Learn more about setting up your dashboard')"
  />
</template>
