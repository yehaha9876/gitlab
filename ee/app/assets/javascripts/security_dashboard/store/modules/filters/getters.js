export const getFilter = state => filterId => state.filters.find(filter => filter.id === filterId);
export const getSelectedOption = (state, getters) => filterId =>
  getters.getFilter(filterId).options.find(option => option.selected);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
