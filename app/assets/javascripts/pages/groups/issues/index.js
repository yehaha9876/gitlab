import projectSelect from '~/project_select';

export default () => {
  const filteredSearchEnabled = gl.FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new gl.FilteredSearchManager('issues');
    filteredSearchManager.setup();
  }
  projectSelect();
};
