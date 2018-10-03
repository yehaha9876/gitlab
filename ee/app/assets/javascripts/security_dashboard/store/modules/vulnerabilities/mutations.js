import Vue from 'vue';
import * as types from './mutation_types';

export default {
  [types.REQUEST_VULNERABILITIES](state) {
    state.isLoadingVulnerabilities = true;
  },
  [types.RECEIVE_VULNERABILITIES_SUCCESS](state, payload) {
    state.isLoadingVulnerabilities = false;
    state.errorLoadingVulnerabilities = false;
    state.pageInfo = payload.pageInfo;
    state.vulnerabilities = payload.vulnerabilities;
  },
  [types.RECEIVE_VULNERABILITIES_ERROR](state) {
    state.isLoadingVulnerabilities = false;
    state.errorLoadingVulnerabilities = true;
  },
  [types.REQUEST_VULNERABILITIES_COUNT](state) {
    state.isLoadingVulnerabilitiesCount = true;
  },
  [types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS](state, payload) {
    state.isLoadingVulnerabilitiesCount = false;
    state.errorLoadingVulnerabilities = false;
    state.vulnerabilitiesCount = payload;
  },
  [types.RECEIVE_VULNERABILITIES_COUNT_ERROR](state) {
    state.isLoadingVulnerabilitiesCount = false;
    state.errorLoadingVulnerabilities = true;
  },
  [types.SET_MODAL_DATA](state, payload) {
    Vue.set(state.modal, 'title', payload.name);
    Vue.set(state.modal.data.description, 'value', payload.description);
    Vue.set(state.modal.data.project, 'value', payload.project && payload.project.name_with_namespace);
    Vue.set(state.modal.data.project, 'url', payload.project && payload.project.web_url);
    Vue.set(state.modal.data.file, 'value', payload.location && payload.location.file);
    Vue.set(state.modal.data.identifiers, 'value', payload.identifiers);
    Vue.set(state.modal.data.severity, 'value', payload.severity);
    Vue.set(state.modal.data.confidence, 'value', payload.confidence);
    Vue.set(state.modal.data.solution, 'value', payload.solution);
    Vue.set(state.modal.data.links, 'value', payload.links);
    Vue.set(state.modal.data.instances, 'value', payload.instances);
  },
};
