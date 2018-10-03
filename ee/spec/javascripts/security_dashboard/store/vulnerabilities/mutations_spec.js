import initialState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as types from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/vulnerabilities/mutations';

describe('vulnerabilities module mutations', () => {
  describe('REQUEST_VULNERABILITIES', () => {
    it('should set `isLoadingVulnerabilities` to `true`', () => {
      const state = initialState;

      mutations[types.REQUEST_VULNERABILITIES](state);

      expect(state.isLoadingVulnerabilities).toBeTruthy();
    });
  });

  describe('RECEIVE_VULNERABILITIES_SUCCESS', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = {
        vulnerabilities: [1, 2, 3, 4, 5],
        pageInfo: { a: 1, b: 2, c: 3 },
      };
      state = initialState();
      mutations[types.RECEIVE_VULNERABILITIES_SUCCESS](state, payload);
    });

    it('should set `isLoadingVulnerabilities` to `false`', () => {
      expect(state.isLoadingVulnerabilities).toBeFalsy();
    });

    it('should set `errorLoadingData` to `false`', () => {
      expect(state.errorLoadingData).toBeFalsy();
    });

    it('should set `pageInfo`', () => {
      expect(state.pageInfo).toBe(payload.pageInfo);
    });

    it('should set `vulnerabilities`', () => {
      expect(state.vulnerabilities).toBe(payload.vulnerabilities);
    });
  });

  describe('RECEIVE_VULNERABILITIES_ERROR', () => {
    it('should set `isLoadingVulnerabilities` to `false`', () => {
      const state = initialState();

      mutations[types.RECEIVE_VULNERABILITIES_ERROR](state);

      expect(state.isLoadingVulnerabilities).toBeFalsy();
    });
  });

  describe('REQUEST_VULNERABILITIES_COUNT', () => {
    it('should set `isLoadingVulnerabilitiesCount` to `true`', () => {
      const state = initialState();

      mutations[types.REQUEST_VULNERABILITIES_COUNT](state);

      expect(state.isLoadingVulnerabilitiesCount).toBeTruthy();
    });
  });

  describe('RECEIVE_VULNERABILITIES_COUNT_SUCCESS', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = { a: 1, b: 2, c: 3 };
      state = initialState();
      mutations[types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS](state, payload);
    });

    it('should set `isLoadingVulnerabilitiesCount` to `false`', () => {
      expect(state.isLoadingVulnerabilitiesCount).toBeFalsy();
    });

    it('should set `errorLoadingData` to `false`', () => {
      expect(state.errorLoadingData).toBeFalsy();
    });

    it('should set `vulnerabilitiesCount`', () => {
      expect(state.vulnerabilitiesCount).toBe(payload);
    });
  });

  describe('RECEIVE_VULNERABILITIES_COUNT_ERROR', () => {
    it('should set `isLoadingVulnerabilitiesCount` to `false`', () => {
      const state = initialState();

      mutations[types.RECEIVE_VULNERABILITIES_COUNT_ERROR](state);

      expect(state.isLoadingVulnerabilitiesCount).toBeFalsy();
    });
  });

  describe('SET_MODAL_DATA', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = {
        name: 'name',
        location: {
          file: 'file',
        },
        project: {
          name_with_namespace: 'name_with_namespace',
          web_url: 'web_url',
        },
        identifiers: [1, 2, 3],
        severity: 'severity',
        confidence: 'confidence',
        solution: 'solution',
        links: [1, 2, 3],
        instances: [1, 2, 3],
      };
      state = initialState();
      mutations[types.SET_MODAL_DATA](state, payload);
    });

    it('should set the title', () => {
      expect(state.modal.title).toEqual(payload.name);
    });

    it('should set the description', () => {
      expect(state.modal.data.description.value).toEqual(payload.description);
    });

    it('should set the project', () => {
      expect(state.modal.data.project.value).toEqual(payload.project.name_with_namespace);
      expect(state.modal.data.project.url).toEqual(payload.project.web_url);
    });

    it('should set the file', () => {
      expect(state.modal.data.file.value).toEqual(payload.location.file);
    });

    it('should set the identifiers', () => {
      expect(state.modal.data.identifiers.value).toEqual(payload.identifiers);
    });

    it('should set the severity', () => {
      expect(state.modal.data.severity.value).toEqual(payload.severity);
    });

    it('should set the confidence', () => {
      expect(state.modal.data.confidence.value).toEqual(payload.confidence);
    });

    it('should set the solution', () => {
      expect(state.modal.data.solution.value).toEqual(payload.solution);
    });

    it('should set the links', () => {
      expect(state.modal.data.links.value).toEqual(payload.links);
    });

    it('should set the instances', () => {
      expect(state.modal.data.instances.value).toEqual(payload.instances);
    });

  });
});
