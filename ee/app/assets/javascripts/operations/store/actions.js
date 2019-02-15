import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { __, s__, n__, sprintf } from '~/locale';
import * as types from './mutation_types';
import _ from 'underscore';

export const addProjectsToDashboard = ({ state, dispatch }) => {
  axios
    .post(state.projectEndpoints.add, {
      project_ids: state.selectedProjects.map(project => project.id),
    })
    .then(response => dispatch('requestAddProjectsToDashboardSuccess', response.data))
    .catch(() => dispatch('requestAddProjectsToDashboardError'));
};

export const toggleSelectedProject = ({ commit, state }, project) => {
  const existingProjects = _.where(state.selectedProjects, { id: project.id });

  if (_.isEmpty(existingProjects)) {
    commit(types.SET_SELECTED_PROJECTS, state.selectedProjects.concat(project));
  } else {
    commit(types.SET_SELECTED_PROJECTS, _.without(state.selectedProjects, ...existingProjects));
  }
};

export const updateSelectedProjects = ({ commit }, projects) => {
  commit(types.SET_SELECTED_PROJECTS, projects);
};

export const clearSearchResults = ({ commit }) => {
  commit(types.SET_PROJECT_SEARCH_RESULTS, []);
  commit(types.SET_SELECTED_PROJECTS, []);
};

export const requestAddProjectsToDashboardSuccess = ({ dispatch, state }, data) => {
  const { added, invalid } = data;

  if (invalid.length) {
    const projectNames = state.selectedProjects.reduce((accumulator, project) => {
      if (invalid.includes(project.id)) {
        accumulator.push(project.name);
      }
      return accumulator;
    }, []);
    let invalidProjects;
    if (projectNames.length > 2) {
      invalidProjects = `${projectNames.slice(0, -1).join(', ')}, and ${projectNames.pop()}`;
    } else if (projectNames.length > 1) {
      invalidProjects = projectNames.join(' and ');
    } else {
      [invalidProjects] = projectNames;
    }
    createFlash(
      sprintf(
        s__(
          'OperationsDashboard|Unable to add %{invalidProjects}. The Operations Dashboard is available for public projects, and private projects in groups with a Gold plan.',
        ),
        { invalidProjects },
      ),
    );
  }

  if (added.length) {
    dispatch('fetchProjects');
  }
};

export const requestAddProjectsToDashboardError = ({ state }) => {
  createFlash(
    sprintf(__('Something went wrong, unable to add %{project} to dashboard'), {
      project: n__('project', 'projects', state.selectedProjects.length),
    }),
  );
};

export const fetchProjects = ({ state, dispatch }) => {
  dispatch('requestProjects');
  axios
    .get(state.projectEndpoints.list)
    .then(response => dispatch('receiveProjectsSuccess', response.data))
    .catch(() => dispatch('receiveProjectsError'))
    .then(() => dispatch('requestProjects'))
    .catch(() => {});
};

export const requestProjects = ({ commit }) => {
  commit(types.TOGGLE_IS_LOADING_PROJECTS);
};

export const receiveProjectsSuccess = ({ commit }, data) => {
  commit(types.SET_PROJECTS, data.projects);
};

export const receiveProjectsError = ({ commit }) => {
  commit(types.SET_PROJECTS, null);
  createFlash(__('Something went wrong, unable to get operations projects'));
};

export const removeProject = ({ dispatch }, removePath) => {
  axios
    .delete(removePath)
    .then(() => dispatch('requestRemoveProjectSuccess'))
    .catch(() => dispatch('requestRemoveProjectError'));
};

export const requestRemoveProjectSuccess = ({ dispatch }) => {
  dispatch('fetchProjects');
};

export const requestRemoveProjectError = () => {
  createFlash(__('Something went wrong, unable to remove project'));
};

export const searchProjects = ({ commit }, query) => {
  if (!query) {
    commit(types.SET_PROJECT_SEARCH_RESULTS, []);
    commit(types.SET_NO_RESULTS, false);
    commit(types.SET_SEARCH_ERROR, false);
  } else {
    commit(types.INCREMENT_PROJECT_SEARCH_COUNT, 1);

    Api.projects(query, {})
      .then(results => {
        commit(types.SET_PROJECT_SEARCH_RESULTS, results);

        const noResults = results.length === 0 && query.length > 0;
        commit(types.SET_NO_RESULTS, noResults);
        commit(types.SET_SEARCH_ERROR, false);
        commit(types.DECREMENT_PROJECT_SEARCH_COUNT, 1);
      })
      .catch(() => {
        commit(types.SET_PROJECT_SEARCH_RESULTS, []);
        commit(types.SET_NO_RESULTS, false);
        commit(types.SET_SEARCH_ERROR, true);
        commit(types.DECREMENT_PROJECT_SEARCH_COUNT, 1);
      });
  }
};

export const setProjectEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_PROJECT_ENDPOINT_LIST, endpoints.list);
  commit(types.SET_PROJECT_ENDPOINT_ADD, endpoints.add);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
