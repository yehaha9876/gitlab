<script>
import Icon from '~/vue_shared/components/icon.vue';
/**
 * Renders the error row for each security report
 */
export default {
  name: 'SecurityErrorRow',
  functional: true,
  components: {
    Icon,
  },
};
</script>
<template>
  <li class="report-block-list-issue">
    <icon
      name="error"
    />
    {{ __("There was an error loading results")}}
  </li>
</template>
