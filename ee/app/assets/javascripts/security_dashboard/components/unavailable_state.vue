<script>
import EmptyState from './empty_state.vue';

export default {
  name: 'UnavailableState',
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
    :svg-alt="s__('Security Reports|Security Dashboard Unavailable')"
    :heading="s__('Security Reports|Oops, something doesn\'t seem right.')"
    :message="
      s__(
        'Security Reports|Either you don\'t have permission to view this dashboard or the dashboard has not been setup. Please check your permission settings with your administrator or check your dashboard configurations to proceed.',
      )
    "
    :link="link"
    :link-text="s__('Security Reports|Learn more about setting up your dashboard')"
  />
</template>
