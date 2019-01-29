import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { __, s__, n__, sprintf } from '~/locale';
import * as types from './mutation_types';

export const addProjectsToDashboard = ({ state, dispatch }) => {
  axios
    .post(state.projectEndpoints.add, {
      project_ids: state.projectTokens.map(project => project.id),
    })
    .then(response => dispatch('requestAddProjectsToDashboardSuccess', response.data))
    .catch(() => dispatch('requestAddProjectsToDashboardError'));
};

export const clearInputValue = ({ commit }) => {
  commit(types.SET_INPUT_VALUE, '');
};

export const clearProjectTokens = ({ commit }) => {
  commit(types.SET_PROJECT_TOKENS, []);
};

export const filterProjectTokensById = ({ commit, state }, ids) => {
  const tokens = state.projectTokens.filter(token => ids.includes(token.id));
  commit(types.SET_PROJECT_TOKENS, tokens);
};

export const requestAddProjectsToDashboardSuccess = ({ dispatch, state }, data) => {
  const { added, invalid } = data;

  dispatch('clearInputValue');

  if (invalid.length) {
    const projectNames = state.projectTokens.reduce((accumulator, project) => {
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
    dispatch('filterProjectTokensById', invalid);
  } else {
    dispatch('clearProjectTokens');
  }

  if (added.length) {
    dispatch('fetchProjects');
  }
};

export const requestAddProjectsToDashboardError = ({ state }) => {
  createFlash(
    sprintf(__('Something went wrong, unable to add %{project} to dashboard'), {
      project: n__('project', 'projects', state.projectTokens.length),
    }),
  );
};

export const addProjectToken = ({ commit }, project) => {
  commit(types.ADD_PROJECT_TOKEN, project);
  commit(types.SET_INPUT_VALUE, '');
};

export const clearProjectSearchResults = ({ commit }) => {
  commit(types.SET_PROJECT_SEARCH_RESULTS, []);
};

const getRandomPipelineStatus = () => {
  const max = 3;
  const min = 1;
  const choice = Math.floor(Math.random() * (max - min + 1) + min);

  switch (choice) {
    case 1:
      return {
        group: 'running',
        icon: 'status_running',
        text: 'running',
        details_path: '/h5bp/html5-boilerplate/pipelines/50',
      };
    case 2:
      return {
        group: 'failed',
        icon: 'status_failed',
        text: 'failed',
        details_path: '/h5bp/html5-boilerplate/pipelines/50',
      };
    case 3:
      return {
        group: 'success',
        icon: 'status_success',
        text: 'success',
        details_path: '/h5bp/html5-boilerplate/pipelines/50',
      };
    default:
      return {
        group: 'running',
        icon: 'status_running',
        text: 'running',
        details_path: '/h5bp/html5-boilerplate/pipelines/50',
      };
  }
}

const tempDashboardApiAdditions = response => {
  const projects = response.data.projects.map(project => {
    const newProject = { ...project };
    if (newProject.last_deployment) {
      newProject.last_deployment.user = {"id":1786152,"name":"🤖 GitLab Bot 🤖","username":"gitlab-bot","state":"active","avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=46&d=identicon","web_url":"https://gitlab.com/gitlab-bot","status_tooltip_html":null,"path":"/gitlab-bot"};
      newProject.last_deployment.commit.author = {"id":1786152,"name":"🤖 GitLab Bot 🤖","username":"gitlab-bot","state":"active","avatar_url":"https://assets.gitlab-static.net/uploads/-/system/user/avatar/1786152/avatar.png","web_url":"https://gitlab.com/gitlab-bot","status_tooltip_html":null,"path":"/gitlab-bot"};
      newProject.last_deployment.finished_time = '2018-11-09T20:04:05.392Z';
    }

    newProject.upstream_pipeline_status = getRandomPipelineStatus();
    newProject.pipeline_status = getRandomPipelineStatus();
    newProject.downstream_pipelines = [
      getRandomPipelineStatus(),
      getRandomPipelineStatus(),
      getRandomPipelineStatus(),
    ];
    return newProject;
  });
  return {
    data: {
      projects,
    },
  };
};

export const fetchProjects = ({ state, dispatch }) => {
  dispatch('requestProjects');
  axios
    .get(state.projectEndpoints.list)
    .then(response => tempDashboardApiAdditions(response))
    .then(response => dispatch('receiveProjectsSuccess', response.data))
    .catch(() => dispatch('receiveProjectsError'))
    .then(() => dispatch('requestProjects'))
    .then(() => {
      setTimeout(() => fetchProjects({ state, dispatch }), 120000);
    })
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

export const removeProjectTokenAt = ({ commit }, index) => {
  commit(types.REMOVE_PROJECT_TOKEN_AT, index);
};

export const searchProjects = ({ commit }, query) => {
  commit(types.INCREMENT_PROJECT_SEARCH_COUNT, 1);

  Api.projects(query, {})
    .then(data => data)
    .catch(() => [])
    .then(results => {
      commit(types.SET_PROJECT_SEARCH_RESULTS, results);
      commit(types.DECREMENT_PROJECT_SEARCH_COUNT, 1);
    })
    .catch(() => {});
};

export const setInputValue = ({ commit }, value) => {
  commit(types.SET_INPUT_VALUE, value);
};

export const setProjectEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_PROJECT_ENDPOINT_LIST, endpoints.list);
  commit(types.SET_PROJECT_ENDPOINT_ADD, endpoints.add);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
