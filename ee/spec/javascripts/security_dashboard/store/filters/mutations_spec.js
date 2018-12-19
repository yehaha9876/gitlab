import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as types from 'ee/security_dashboard/store/modules/filters/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/filters/mutations';

describe('filters module mutations', () => {
  describe('SET_FILTER', () => {
    let state;
    let firstFilter;
    let firstOption;
    let secondOption;

    beforeEach(() => {
      state = createState();
      [firstFilter] = state.filters;
      [firstOption, secondOption] = firstFilter.options;

      const filterId = firstFilter.id;
      const optionId = secondOption.id;

      mutations[types.SET_FILTER](state, { filterId, optionId });
    });

    it('should select the second option', () => {
      expect(secondOption.selected).toEqual(true);
    });

    it('should deselect the first option', () => {
      expect(firstOption.selected).toEqual(false);
    });
  });

  describe('ADD_FILTER_OPTIONS', () => {
    let state;
    let firstFilter;
    const options = [{ id: 0, name: 'c' }, { id: 3, name: 'c' }];

    beforeEach(() => {
      state = createState();
      [firstFilter] = state.filters;
      const filterId = firstFilter.id;

      mutations[types.ADD_FILTER_OPTIONS](state, { filterId, options });
    });

    it('should add all the options to the type filter', () => {
      expect(firstFilter.options).toEqual(options);
    });
  });
});
