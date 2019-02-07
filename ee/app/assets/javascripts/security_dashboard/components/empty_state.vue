<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'EmptyState',
  components: {
    GlButton,
  },
  props: {
    svgPath: {
      type: String,
      required: true,
    },
    svgAlt: {
      type: String,
      required: true,
    },
    link: {
      type: String,
      required: true,
    },
    heading: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: true,
    },
    linkText: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="empty-state row">
    <div class="col-12">
      <div class="svg-content svg-250">
        <img :src="svgPath" :alt="svgAlt" />
      </div>
      <div class="text-content">
        <h4>{{ heading }}</h4>
        <p>
          {{ message }}
        </p>
        <div class="text-center">
          <gl-button variant="success" :href="link"> {{ linkText }}</gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
