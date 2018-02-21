<script>
  import icon from '../../../vue_shared/components/icon.vue';

  export default {
    components: {
      icon,
    },
    props: {
      files: {
        type: Array,
        required: true,
      },
      icon: {
        type: String,
        required: true,
      },
    },
    computed: {
      addedFiles() {
        return this.files.filter(f => f.tempFile);
      },
      modifiedFiles() {
        return this.files.filter(f => !f.tempFile);
      },
      addedFilesIconClass() {
        return `${this.addedFiles.length ? 'multi-file-addition' : ''} append-bottom-10`;
      },
      modifiedFilesClass() {
        return `${this.modifiedFiles.length ? 'multi-file-modified' : ''} prepend-top-10 append-bottom-10`;
      },
    },
  };
</script>

<template>
  <div
    class="multi-file-commit-list-collapsed text-center"
  >
    <icon
      v-once
      :name="icon"
      :size="18"
      css-classes="append-bottom-15"
    />
    <icon
      name="file-addition"
      :size="18"
      :css-classes="addedFilesIconClass"
    />
    {{ addedFiles.length }}
    <icon
      name="file-modified"
      :size="18"
      :css-classes="modifiedFilesClass"
    />
    {{ modifiedFiles.length }}
  </div>
</template>
