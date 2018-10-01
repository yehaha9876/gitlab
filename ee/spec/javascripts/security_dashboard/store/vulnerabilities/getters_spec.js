import initialState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as getters from 'ee/security_dashboard/store/modules/vulnerabilities/getters';

describe('vulnerabilities module getters', () => {
  describe('pageInfo', () => {
    it('should get the pageInfo object from the state', () => {
      const pageInfo = { page: 1 };
      const state = { pageInfo };
      const result = getters.pageInfo(state);

      expect(result).toBe(pageInfo);
    });
  });

  describe('vulnerabilities', () => {
    it('should get the vulnerabilities from the state', () => {
      const vulnerabilities = [1, 2, 3, 4, 5];
      const state = { vulnerabilities };
      const result = getters.vulnerabilities(state);

      expect(result).toBe(vulnerabilities);
    });

    it('should get an empty array when there are no vulnerabilities in the state', () => {
      const result = getters.vulnerabilities(initialState);

      expect(result).toEqual([]);
    });
  });

  describe('isLoadingVulnerabilities', () => {
    it('should return the loading state from the store', () => {
      const isLoadingVulnerabilities = true;
      const state = { isLoadingVulnerabilities };
      const result = getters.isLoadingVulnerabilities(state);

      expect(result).toBe(isLoadingVulnerabilities);
    });
  });

  describe('vulnerabilitiesCount', () => {
    it('should get the vulnerabilitiesCount from the state', () => {
      const vulnerabilitiesCount = { a: 1, b: 2, c: 3 };
      const state = { vulnerabilitiesCount };
      const result = getters.vulnerabilitiesCount(state);

      expect(result).toBe(vulnerabilitiesCount);
    });

    it('should get an empty array when there are no vulnerabilities in the state', () => {
      const result = getters.vulnerabilitiesCount(initialState);

      expect(result).toEqual({});
    });
  });

  describe('isLoadingVulnerabilitiesCount', () => {
    it('should return the loading state from the store', () => {
      const isLoadingVulnerabilities = true;
      const state = { isLoadingVulnerabilities };
      const result = getters.isLoadingVulnerabilities(state);

      expect(result).toBe(isLoadingVulnerabilities);
    });
  });

  describe('vulnerabilitiesCountBySeverity', () => {
    const sast = { critical: 10 };
    const dast = { critical: 66 };
    const expectedValue = sast.critical + dast.critical;
    const vulnerabilitiesCount = { sast, dast };
    const state = { vulnerabilitiesCount };
    const mockedGetters = { vulnerabilitiesCount };

    it('should add up all the counts with `high` severity', () => {
      const result = getters.vulnerabilitiesCountBySeverity(state, mockedGetters)('critical');

      expect(result).toBe(expectedValue);
    });

    it('should return 0 if no counts match the severity name', () => {
      const result = getters.vulnerabilitiesCountBySeverity(state, mockedGetters)('medium');

      expect(result).toBe(0);
    });

    it('should return 0 if there are no counts at all', () => {
      const emptyMockedGetters = { vulnerabilitiesCount: {} };
      const result = getters.vulnerabilitiesCountBySeverity(initialState, emptyMockedGetters)('critical');

      expect(result).toBe(0);
    });
  });

  describe('vulnerabilitiesCountByReportType', () => {
    const sast = { critical: 10, medium: 22 };
    const dast = { critical: 66 };
    const expectedValue = sast.critical + sast.medium;
    const vulnerabilitiesCount = { sast, dast };
    const state = { vulnerabilitiesCount };
    const mockedGetters = { vulnerabilitiesCount };

    it('should add up all the counts in the sast report', () => {
      const result = getters.vulnerabilitiesCountByReportType(state, mockedGetters)('sast');

      expect(result).toBe(expectedValue);
    });

    it('should return 0 if there are no reports for a severity type', () => {
      const emptyMockedGetters = { vulnerabilitiesCount: {} };
      const result = getters.vulnerabilitiesCountByReportType(initialState, emptyMockedGetters)('sast');

      expect(result).toBe(0);
    });
  });
});
