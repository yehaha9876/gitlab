import {
  GlLoadingIcon
} from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
  },
  data() {
    return {
      hasError: false,
    };
  },
  computed: {
    shouldRenderPagination() {
      return (
        !this.isLoading &&
        this.state.featureFlags.length &&
        this.state.pageInfo.total > this.state.pageInfo.perPage
      );
    },
  },
  beforeMount() {
    this.getFeatureFlags();
  },
  methods: {
    /**
     * Handles URL and query parameter changes.
     * When the user uses the pagination or the tabs,
     *  - update URL
     *  - Make API request to the server with new parameters
     *  - Update the internal state
     */
    updateContent(parameters) {
      this.updateInternalState(parameters);

      // fetch new data
      return this.getFeatureFlags();
    },
    getFeatureFlags() {
      return this.service
        .getFeatureFlags(this.requestData)
        .then(response => this.successCallback(response))
        .catch(() => this.errorCallback());
    },
    setCommonData(featureFlags) {
      this.store.storeFeatureFlags(featureFlags);
      this.isLoading = false;
      this.hasError = false;
    },
    successCallback(resp) {
      this.store.storeCount(resp.data.count);
      this.store.storePagination(resp.headers);
      this.setCommonData(resp.data.features);
    },
    errorCallback() {
      this.isLoading = false;
      this.hasError = true;
    },
  }
}