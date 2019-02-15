<script>
import _ from 'underscore';
import { mapState, mapActions } from 'vuex';
import { GlModal, GlLoadingIcon, GlModalDirective } from '@gitlab/ui';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import DashboardProject from './project.vue';

export default {
  components: {
    DashboardProject,
    GlLoadingIcon,
    GlModal,
    ProjectSelector,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  props: {
    addPath: {
      type: String,
      required: true,
    },
    listPath: {
      type: String,
      required: true,
    },
    emptyDashboardSvgPath: {
      type: String,
      required: true,
    },
    emptyDashboardHelpPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      modalId: 'add-projects-modal',
    };
  },
  computed: {
    ...mapState([
      'projects',
      'projectTokens',
      'isLoadingProjects',
      'selectedProjects',
      'noResults',
      'searchErrorMessage',
      'projectSearchResults',
      'searchCount',
    ]),
    isSearchingProjects() {
      return this.searchCount > 0;
    },
    okDisabled() {
      return _.isEmpty(this.selectedProjects);
    },
  },
  created() {
    this.setProjectEndpoints({
      list: this.listPath,
      add: this.addPath,
    });
    this.fetchProjects();
  },
  methods: {
    ...mapActions([
      'searchProjects',
      'addProjectsToDashboard',
      'updateSelectedProjects',
      'fetchProjects',
      'setProjectEndpoints',
      'clearSearchResults',
      'toggleSelectedProject',
    ]),
    addProjects() {
      this.addProjectsToDashboard();
    },
    onModalShown() {
      this.clearSearchResults();
      this.$refs.projectSelector.focusSearchInput();
    },
    onOk() {
      this.addProjectsToDashboard();
    },
    searched(query) {
      this.searchProjects(query);
    },
    projectClicked(project) {
      this.toggleSelectedProject(project);
    },
  },
};
</script>

<template>
  <div class="operations-dashboard">
    <gl-modal
      :modal-id="modalId"
      :title="s__('Add projects')"
      :ok-title="s__('Add projects')"
      :ok-disabled="okDisabled"
      ok-variant="success"
      @shown="onModalShown"
      @ok="onOk"
    >
      <project-selector
        ref="projectSelector"
        :project-search-results="projectSearchResults"
        :selected-projects="selectedProjects"
        :no-results="noResults && !searchErrorMessage"
        @searched="searched"
        @projectClicked="projectClicked"
      />
      <p v-if="searchErrorMessage" class="text-danger ml-2">
        {{ __('Something went wrong, unable to search projects') }}
      </p>
      <gl-loading-icon v-if="isSearchingProjects" :size="2" class="py-2 px-4" />
    </gl-modal>

    <div class="page-title-holder flex-fill d-flex align-items-center">
      <h1 class="js-dashboard-title page-title text-nowrap flex-fill">
        {{ __('Operations Dashboard') }}
      </h1>
      <button
        v-if="projects.length"
        v-gl-modal="modalId"
        type="button"
        class="js-add-projects-button btn btn-success"
      >
        {{ __('Add projects') }}
      </button>
    </div>
    <div class="prepend-top-default">
      <div v-if="projects.length" class="row m-0 prepend-top-default">
        <div
          v-for="project in projects"
          :key="project.id"
          class="col-12 col-md-6 odds-md-pad-right evens-md-pad-left"
        >
          <dashboard-project :project="project" />
        </div>
      </div>
      <div v-else-if="!isLoadingProjects" class="row prepend-top-20 text-center">
        <div class="col-12 d-flex justify-content-center svg-content">
          <img :src="emptyDashboardSvgPath" class="js-empty-state-svg col-12 prepend-top-20" />
        </div>
        <h4 class="js-title col-12 prepend-top-20">
          {{ s__('OperationsDashboard|Add a project to the dashboard') }}
        </h4>
        <div class="col-12 d-flex justify-content-center">
          <span class="js-sub-title mw-460 text-tertiary text-left">
            {{
              s__(`OperationsDashboard|The operations dashboard provides a summary of each project's
              operational health, including pipeline and alert statuses.`)
            }}
            <a :href="emptyDashboardHelpPath" class="js-documentation-link">
              {{ __('More information') }}
            </a>
          </span>
        </div>
        <div class="col-12">
          <button
            v-gl-modal="modalId"
            type="button"
            class="js-add-projects-button btn btn-success prepend-top-default append-bottom-default"
          >
            {{ __('Add projects') }}
          </button>
        </div>
      </div>
      <gl-loading-icon v-else :size="2" class="prepend-top-20" />
    </div>
  </div>
</template>
