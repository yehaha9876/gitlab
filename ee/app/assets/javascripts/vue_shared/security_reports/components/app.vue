<script>
  import { CI_VIEW, MR_WIDGET } from '../store/constants';
  import store from '../store';
  import { mapActions } from 'vuex';

  export default {
    store,
    props: {
      headBlobPath: {
        type: String,
        required: false,
        default: null,
      },
      baseBlobPath: {
        type: String,
        required: false,
        default: null,
      },
      type: {
        type: String,
        required: true,
      },
      sastHeadPath: {
        type: String,
        required: false,
        default: null,
      },
      sastBasePath: {
        type: String,
        required: false,
        default: null,
      },
      dastHeadPath: {
        type: String,
        required: false,
        default: null,
      },
      dastBasePath: {
        type: String,
        required: false,
        default: null,
      },
      sastContainerHeadPath: {
        type: String,
        required: false,
        default: null,
      },
      sastContainerBasePath: {
        type: String,
        required: false,
        default: null,
      },
    },
    methods: {
      ...mapActions([
        'setAppType',
        'setHeadBlobPath',
        'setBaseBlobPath',
        'setSastHeadPath',
        'setSastBasePath',
        'setSastContainerHeadPath',
        'setSastContainerBasePath',
        'setDastHeadPath',
        'setDastBasePath',
      ]),
    },

    computed: {
      isCiView() {
        return type === CI_VIEW;
      },
      isMRWidget() {
        return type === MR_WIDGET;
      },
    },

    created() {
      // update the store with the received props
      this.setAppType(this.type);
      if (this.headBlobPath) {
        this.setHeadBlobPath(this.headBlobPath);
      }

      if (this.baseBlobPath) {
        this.setBaseBlobPath(this.baseBlobPath);
      }

      if (this.sastHeadPath) {
        this.setSastHeadPath(this.sastHeadPath);
      }

      if (this.sastBasePath) {
        this.setSastBasePath(this.sastBasePath);
      }

      if (this.sastContainerBasePath) {
        this.setSastContainerBasePath(this.sastContainerBasePath);
      }

      if (this.sastContainerHeadPath) {
        this.setSastContainerHeadPath(this.sastContainerHeadPath);
      }

      if (this.dastHeadPath) {
        this.setDastHeadPath(this.dastHeadPath);
      }

      if (this.dastBasePath) {
        this.setDastBasePath(this.dastBasePath);
      }

      // Should make requests
    },
  };
</script>
<template>
  <div>
    <template v-if="isCiView">
      <!-- render ungrouped -->
    </template>

    <template v-else-if="isMRWidget">
      <!-- Render Grouped -->
    </template>
  </div>
</template>
