<script>
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
/**
 * Renders the loading row for each security report
 */
export default {
  name: 'SecurityLoadingRow',
  functional: true,
  components: {
    LoadingIcon,
  },
};
</script>
<template>
  <li class="report-block-list-issue">
    <loading-icon />
    {{ __("in progress")}}
  </li>
</template>
