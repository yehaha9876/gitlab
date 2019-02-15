import state from 'ee/operations/store/state';
import mutations from 'ee/operations/store/mutations';
import * as types from 'ee/operations/store/mutation_types';
import { mockProjectData } from '../mock_data';

describe('mutations', () => {
  const projects = mockProjectData(1);
  const mockEndpoint = 'https://mock-endpoint';
  const mockSearches = new Array(5).fill(null);
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('DECREMENT_PROJECT_SEARCH_COUNT', () => {
    it('removes search from searchCount', () => {
      localState.searchCount = mockSearches.length + 2;
      mockSearches.forEach(() => {
        mutations[types.DECREMENT_PROJECT_SEARCH_COUNT](localState, 1);
      });

      expect(localState.searchCount).toBe(2);
    });
  });

  describe('INCREMENT_PROJECT_SEARCH_COUNT', () => {
    it('adds search to searchCount', () => {
      mockSearches.forEach(() => {
        mutations[types.INCREMENT_PROJECT_SEARCH_COUNT](localState, 1);
      });

      expect(localState.searchCount).toBe(mockSearches.length);
    });
  });

  describe('SET_PROJECT_ENDPOINT_LIST', () => {
    it('sets project list endpoint', () => {
      mutations[types.SET_PROJECT_ENDPOINT_LIST](localState, mockEndpoint);

      expect(localState.projectEndpoints.list).toBe(mockEndpoint);
    });
  });

  describe('SET_PROJECT_ENDPOINT_ADD', () => {
    it('sets project add endpoint', () => {
      mutations[types.SET_PROJECT_ENDPOINT_ADD](localState, mockEndpoint);

      expect(localState.projectEndpoints.add).toBe(mockEndpoint);
    });
  });

  describe('SET_SELECTED_PROJECTS', () => {
    it('sets the list of selected projects', () => {
      mutations[types.SET_SELECTED_PROJECTS](localState, projects);

      expect(localState.selectedProjects).toBe(projects);
    });
  });

  describe('SET_PROJECT_SEARCH_RESULTS', () => {
    it('sets project search results', () => {
      mutations[types.SET_PROJECT_SEARCH_RESULTS](localState, projects);

      expect(localState.projectSearchResults).toEqual(projects);
    });
  });

  describe('SET_PROJECTS', () => {
    it('sets projects', () => {
      mutations[types.SET_PROJECTS](localState, projects);

      expect(localState.projects).toEqual(projects);
    });
  });

  describe('SET_NO_RESULTS', () => {
    it('sets the "no results" boolean', () => {
      mutations[types.SET_NO_RESULTS](localState, true);

      expect(localState.noResults).toBe(true);

      mutations[types.SET_NO_RESULTS](localState, false);

      expect(localState.noResults).toBe(false);
    });
  });

  describe('TOGGLE_IS_LOADING_PROJECTS', () => {
    it('toggles the isLoadingProjects boolean', () => {
      mutations[types.TOGGLE_IS_LOADING_PROJECTS](localState);

      expect(localState.isLoadingProjects).toEqual(true);

      mutations[types.TOGGLE_IS_LOADING_PROJECTS](localState);

      expect(localState.isLoadingProjects).toEqual(false);
    });
  });

  describe('SET_SEARCH_ERROR', () => {
    it('sets the searchError boolean', () => {
      mutations[types.SET_SEARCH_ERROR](localState, true);

      expect(localState.searchError).toEqual(true);

      mutations[types.SET_SEARCH_ERROR](localState, false);

      expect(localState.searchError).toEqual(false);
    });
  });
});
