import Store from 'ee/feature_flags/store/feature_flags_store';
import { featureFlag } from './mock_data';

describe('Store', () => {
  let store;

  beforeEach(() => {
    store = new Store();
  });

  it('should start with a blank state', () => {
    expect(store.state.featureFlags.length).toEqual(0);
    expect(store.state.count).toEqual({});
    expect(store.state.pageInfo).toEqual({});
  });

  it('should store feature flags', () => {
    store.storeFeatureFlags([featureFlag]);

    expect(store.state.featureFlags.length).toEqual(1);
    expect(store.state.featureFlags[0]).toEqual(featureFlag);
  });

  it('should store filter counts', () => {
    const count = {
      all: 2,
      enabled: 1,
      disabled: 1,
    };

    store.storeCount(count);

    expect(store.state.count.all).toEqual(2);
    expect(store.state.count.enabled).toEqual(1);
    expect(store.state.count.disabled).toEqual(1);
  });

  it('should store normalized and integer pagination information', () => {
    const pagination = {
      'X-nExt-pAge': '2',
      'X-page': '1',
      'X-Per-Page': '1',
      'X-Prev-Page': '2',
      'X-TOTAL': '37',
      'X-Total-Pages': '2',
    };

    const expectedResult = {
      perPage: 1,
      page: 1,
      total: 37,
      totalPages: 2,
      nextPage: 2,
      previousPage: 2,
    };

    store.storePagination(pagination);

    expect(store.state.pageInfo).toEqual(expectedResult);
  });
});
