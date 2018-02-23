<script>
  import Icon from '../../../vue_shared/components/icon.vue';
  import StageButton from './stage_button.vue';
  import UnstageButton from './unstage_button.vue';

  export default {
    components: {
      Icon,
      StageButton,
      UnstageButton,
    },
    props: {
      file: {
        type: Object,
        required: true,
      },
      actionComponent: {
        type: String,
        required: true,
      },
    },
    computed: {
      iconName() {
        return this.file.tempFile ? 'file-addition' : 'file-modified';
      },
      iconClass() {
        return `multi-file-${this.file.tempFile ? 'addition' : 'modified'} append-right-8`;
      },
    },
  };
</script>

<template>
  <div
    v-once
    class="multi-file-commit-list-item"
  >
    <icon
      :name="iconName"
      :size="16"
      :css-classes="iconClass"
    />
    <span class="multi-file-commit-list-path">
      {{ file.path }}
    </span>
    <component
      :is="actionComponent"
      :file="file"
    />
  </div>
</template>
