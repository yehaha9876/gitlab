import Vue from 'vue';
import Vuex from 'vuex';
import state from 'ee_else_ce/environments/stores/state';

Vue.use(Vuex);

export default dataset =>
  new Vuex.Store({
    state: state(dataset),
  });
