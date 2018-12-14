import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as getters from 'ee/security_dashboard/store/modules/filters/getters';

describe('filters module getters', () => {
  const mockedGetters = {
    getFilter: filterId => getters.getFilter(createState())(filterId),
  };

  describe('getFilter', () => {
    it('should return the type filter information', () => {
      const state = createState();
      const typeFilter = getters.getFilter(state)('type');

      expect(typeFilter.name).toEqual('Report type');
    });
  });

  describe('getSelectedOption', () => {
    it('should return "all" as the selcted option', () => {
      const state = createState();
      const selectedOption = getters.getSelectedOption(state, mockedGetters)('type');

      expect(selectedOption.name).toEqual('All');
    });
  });
});
