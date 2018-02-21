<script>
  import { mapActions, mapState } from 'vuex';
  import icon from '../../../vue_shared/components/icon.vue';
  import listItem from './list_item.vue';
  import listCollapsed from './list_collapsed.vue';

  export default {
    components: {
      icon,
      listItem,
      listCollapsed,
    },
    props: {
      title: {
        type: String,
        required: true,
      },
      fileList: {
        type: Array,
        required: true,
      },
      showToggle: {
        type: Boolean,
        required: false,
        default: true,
      },
      icon: {
        type: String,
        required: true,
      },
      action: {
        type: String,
        required: true,
      },
      actionBtnText: {
        type: String,
        required: true,
      },
      itemAction: {
        type: String,
        required: true,
      },
      itemActionIcon: {
        type: String,
        required: true,
      },
    },
    computed: {
      ...mapState([
        'rightPanelCollapsed',
      ]),
      currentIcon() {
        return this.rightPanelCollapsed ? 'angle-double-left' : 'angle-double-right';
      },
    },
    methods: {
      ...mapActions([
        'setPanelCollapsedStatus',
        'stageAllChanges',
        'unstageAllChanges',
      ]),
      toggleCollapsed() {
        this.setPanelCollapsedStatus({
          side: 'right',
          collapsed: !this.rightPanelCollapsed,
        });
      },
      actionBtnClicked() {
        this[this.action]();
      },
    },
  };
</script>

<template>
  <div
    class="ide-commit-list-container"
    :class="{
      'is-collapsed': rightPanelCollapsed,
    }"
  >
    <header
      class="multi-file-commit-panel-header"
      :class="{
        'is-collapsed': rightPanelCollapsed,
      }"
    >
      <div
        class="multi-file-commit-panel-header-title"
        v-if="!rightPanelCollapsed"
      >
        <icon
          v-once
          :name="icon"
          :size="18"
        />
        {{ title }}
        <button
          type="button"
          class="btn btn-blank btn-link ide-staged-action-btn"
          @click="actionBtnClicked"
        >
          {{ actionBtnText }}
        </button>
      </div>
      <button
        v-if="showToggle"
        type="button"
        class="btn btn-transparent multi-file-commit-panel-collapse-btn"
        @click.stop="toggleCollapsed"
      >
        <icon
          :name="currentIcon"
          :size="18"
        />
      </button>
    </header>
    <list-collapsed
      v-if="rightPanelCollapsed"
      :files="fileList"
      :icon="icon"
    />
    <template v-else>
      <ul
        v-if="fileList.length"
        class="multi-file-commit-list list-unstyled append-bottom-0"
      >
        <li
          v-for="file in fileList"
          :key="file.key"
        >
          <list-item
            :file="file"
            :action="itemAction"
            :action-icon="itemActionIcon"
          />
        </li>
      </ul>
      <p
        v-else
        class="multi-file-commit-list"
      >
        No changes
      </p>
    </template>
  </div>
</template>
