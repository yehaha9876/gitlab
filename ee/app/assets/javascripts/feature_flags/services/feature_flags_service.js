import axios from '~/lib/utils/axios_utils';

export default class FeatureFlagsService {
  /**
   * Endpoint URL for the feature flags
   *
   * @param  {String} root
   */
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  getFeatureFlags(data = {}) {
    const { CancelToken } = axios;

    this.cancelationSource = CancelToken.source();

    return axios.get(this.endpoint, {
      params: data,
      cancelToken: this.cancelationSource.token,
    });
  }
}
