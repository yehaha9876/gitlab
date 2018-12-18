import {
  parseIntPagination,
  normalizeHeaders
} from '../../../../../../app/assets/javascripts/lib/utils/common_utils';

export default class FeatureFlagsStore {
  constructor() {
    this.state = {};

    this.state.featureFlags = [];
    this.state.count = {};
    this.state.pageInfo = {};
  }

  storeFeatureFlags(featureFlags = []) {
    this.state.featureFlags = featureFlags;
  }

  storeCount(count = {}) {
    this.state.count = count;
  }

  storePagination(pagination = {}) {
    let paginationInfo;

    if (Object.keys(pagination).length) {
      const normalizedHeaders = normalizeHeaders(pagination);
      paginationInfo = parseIntPagination(normalizedHeaders);
    } else {
      paginationInfo = pagination;
    }

    this.state.pageInfo = paginationInfo;
  }
}