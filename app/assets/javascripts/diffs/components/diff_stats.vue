<script>
import Icon from '~/vue_shared/components/icon.vue';
import { n__ } from '~/locale';

export default {
  components: { Icon },
  props: {
    addedLines: {
      type: Number,
      required: true,
    },
    removedLines: {
      type: Number,
      required: true,
    },
    diffFilesLength: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    filesText() {
      return n__('File', 'Files', this.diffFilesLength);
    }
  }
};
</script>

<template>
  <div class="DiffStats" :class="{ isCompareVersionsHeader: Boolean(diffFilesLength) }">
    <div v-if="diffFilesLength" class="DiffStats-group">
      <icon name="doc-code" class="DiffStats-icon text-secondary" />
      <strong>{{ diffFilesLength }}</strong> {{ filesText }}
    </div>
    <div class="DiffStats-group cgreen">
      <icon name="file-addition" class="DiffStats-icon" /> <strong>{{ addedLines }}</strong>
    </div>
    <div class="DiffStats-group cred">
      <icon name="file-deletion" class="DiffStats-icon" /> <strong>{{ removedLines }}</strong>
    </div>
  </div>
</template>
