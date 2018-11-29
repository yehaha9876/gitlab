import Vue from 'vue';
import VueApollo from 'vue-apollo';
import defaultClient from '~/lib/graphql';
import Translate from '~/vue_shared/translate';
import { convertPermissionToBoolean } from '~/lib/utils/common_utils';
import InstanceLicense from './components/instance_licenses.vue';

Vue.use(Translate);
Vue.use(VueApollo);

export default function mountInstanceLicenseApp(mountElement) {
  if (!mountElement) return undefined;

  const apolloProvider = new VueApollo({
    defaultClient,
  });

  return new Vue({
    el: mountElement,
    apolloProvider,
    render(createElement) {
      return createElement(InstanceLicense);
    },
  });
}
