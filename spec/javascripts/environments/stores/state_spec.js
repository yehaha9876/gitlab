import state from '~/environments/stores/state';
import {
  environmentsAppDataset,
  environmentsAppData,
  environmentsFolderDataset,
  environmentsFolderData,
} from '../mock_data';

describe('environments store state', () => {
  describe('initialization using environments data', () => {
    it('handles dataset for environments app', () => {
      expect(state(environmentsAppDataset)).toEqual(environmentsAppData);
    });

    it('handles dataset for environments folders', () => {
      expect(state(environmentsFolderDataset)).toEqual(environmentsFolderData);
    });
  });
});
