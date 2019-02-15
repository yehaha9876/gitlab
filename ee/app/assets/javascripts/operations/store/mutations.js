import * as types from './mutation_types';

export default {
  [types.DECREMENT_PROJECT_SEARCH_COUNT](state, value) {
    state.searchCount -= value;
  },
  [types.INCREMENT_PROJECT_SEARCH_COUNT](state, value) {
    state.searchCount += value;
  },
  [types.SET_PROJECT_ENDPOINT_LIST](state, url) {
    state.projectEndpoints.list = url;
  },
  [types.SET_PROJECT_ENDPOINT_ADD](state, url) {
    state.projectEndpoints.add = url;
  },
  [types.SET_SELECTED_PROJECTS](state, projects) {
    state.selectedProjects = projects;
  },
  [types.SET_PROJECT_SEARCH_RESULTS](state, results) {
    state.projectSearchResults = results;
  },
  [types.SET_PROJECTS](state, projects) {
    state.projects = projects || [];
  },
  [types.SET_NO_RESULTS](state, value) {
    state.noResults = value;
  },
  [types.TOGGLE_IS_LOADING_PROJECTS](state) {
    state.isLoadingProjects = !state.isLoadingProjects;
  },
  [types.SET_SEARCH_ERROR](state, value) {
    state.searchError = value;
  },
};
