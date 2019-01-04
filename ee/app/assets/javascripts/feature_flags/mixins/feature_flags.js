import { GlLoadingIcon } from '@gitlab/ui';
import SvgBlankState from '../components/blank_state.vue';

export default {
  components: {
    GlLoadingIcon,
    SvgBlankState,
  },
  data() {
    return {
      isLoading: true,
      hasError: false,
    };
  },
  beforeMount() {
    this.getFeatureFlags();
  },
  methods: {
    updateContent(parameters) {
      this.updateInternalState(parameters);

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
      this.setCommonData(resp.data.feature_flags);
    },
    errorCallback() {
      this.isLoading = false;
      this.hasError = true;
    },
  },
};
