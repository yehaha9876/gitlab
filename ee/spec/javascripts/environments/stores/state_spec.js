import state from 'ee/environments/stores/state';
import {
  environmentsAppDataset,
  environmentsAppData,
  environmentsFolderDataset,
  environmentsFolderData,
} from 'spec/environments/mock_data';
import { environmentsDataset, environmentsData } from '../mock_data';

describe('ee environments store state', () => {
  describe('initialization using environments data', () => {
    it('handles dataset for environments app', () => {
      expect(state(Object.assign({}, environmentsAppDataset, environmentsDataset))).toEqual(
        Object.assign({}, environmentsAppData, environmentsData),
      );
    });

    it('handles dataset for environments folders', () => {
      expect(state(Object.assign({}, environmentsFolderDataset, environmentsDataset))).toEqual(
        Object.assign({}, environmentsFolderData, environmentsData),
      );
    });
  });
});
