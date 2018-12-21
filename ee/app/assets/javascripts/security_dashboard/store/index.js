import Vue from 'vue';
import Vuex from 'vuex';
import filters from './modules/filters/index';
import projects from './modules/projects/index';
import vulnerabilities from './modules/vulnerabilities/index';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      filters,
      projects,
      vulnerabilities,
    },
  });
