<script>
import { GlPopover } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlPopover,
    Icon,
  },
  props: {
    dashboardDocumentation: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <span class="vertical-align-middle text-muted js-help">
    <icon id="reports-info" name="question" :aria-label="__('help')" />
    <gl-popover
      target="reports-info"
      placement="right"
      :title="s__('Security Reports|At this time, the security dashboard only supports SAST.')"
      triggers="click"
    >
      <a
        v-if="dashboardDocumentation"
        :title="s__('Security Reports|Security dashboard documentation')"
        :href="dashboardDocumentation"
        target="_blank"
        rel="noopener noreferrer"
      >
        <span class="vertical-align-middle">{{
          s__('Security Reports|Security dashboard documentation')
        }}</span>
        <icon name="external-link" :size="16" class="vertical-align-middle" />
      </a>
    </gl-popover>
  </span>
</template>
