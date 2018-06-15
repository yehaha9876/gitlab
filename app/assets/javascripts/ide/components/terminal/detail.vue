<script>
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';

export default {
  components: {
    LoadingIcon,
  },
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="ide-terminal build-page d-flex flex-column flex-fill">
    <loading-icon
      v-if="loading"
      class="prepend-top-default"
      size="2"
    />
    <template v-else>
      <pre
        ref="buildTrace"
        class="build-trace mb-0 h-100"
      >
        <code
          class="bash"
        >
        blablalaa
        </code>
        <div
          class="build-loader-animation"
        >
        </div>
      </pre>
    </template>
  </div>
</template>
