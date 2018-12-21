import * as types from './mutation_types';

export default {
  [types.SET_FILTER](state, payload) {
    const { filterId, optionId } = payload;
    const activeFilter = state.filters.find(filter => filter.id === filterId);
    activeFilter.options.find(option => option.selected).selected = false;
    activeFilter.options.find(option => option.id === optionId).selected = true;
  },
  [types.ADD_FILTER_OPTIONS](state, payload) {
    const { filterId, options } = payload;
    state.filters.find(filter => filter.id === filterId).options = options;
  },
};
