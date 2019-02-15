export default () => ({
  inputValue: '',
  isLoadingProjects: false,
  projectEndpoints: {
    list: null,
    add: null,
  },
  searchQuery: '',
  projects: [],
  projectSearchResults: [],
  selectedProjects: [],
  noResults: false,
  searchError: false,
  searchCount: 0,
});
