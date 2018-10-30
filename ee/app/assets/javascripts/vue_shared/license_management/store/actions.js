import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import { LICENSE_APPROVAL_STATUS } from '../constants';

export const setAPISettings = ({ commit }, data) => {
  commit(types.SET_API_SETTINGS, data);
};

export const setLicenseInModal = ({ commit }, license) => {
  commit(types.SET_LICENSE_IN_MODAL, license);
};

export const resetLicenseInModal = ({ commit }) => {
  commit(types.RESET_LICENSE_IN_MODAL);
};

export const deleteLicense = ({ commit, dispatch, state }) => {
  const licenseId = state.currentLicenseInModal.id;
  commit(types.REQUEST_DELETE_LICENSE);
  const endpoint = `${state.apiUrlManageLicenses}/${licenseId}`;
  return axios
    .delete(endpoint)
    .then(() => {
      commit(types.RECEIVE_DELETE_LICENSE);
      dispatch('loadManagedLicenses');
    })
    .catch(error => {
      commit(types.RECEIVE_DELETE_LICENSE_ERROR, error);
    });
};

export const loadManagedLicenses = ({ commit, state }) => {
  commit(types.REQUEST_LOAD_MANAGED_LICENSES);

  const { apiUrlManageLicenses } = state;

  return axios
    .get(apiUrlManageLicenses)
    .then(({ data }) => {
      commit(types.RECEIVE_LOAD_MANAGED_LICENSES, data);
    })
    .catch(error => {
      commit(types.RECEIVE_LOAD_MANAGED_LICENSES_ERROR, error);
    });
};

export const loadLicenseReport = ({ commit, state }) => {
  commit(types.REQUEST_LOAD_LICENSE_REPORT);

  const { headPath, basePath } = state;

  const promises = [axios.get(headPath).then(({ data }) => data)];

  if (basePath) {
    promises.push(
      axios
        .get(basePath)
        .then(({ data }) => data)
        .catch(e => {
          if (e.response.status === 404) {
            return {};
          }

          throw e;
        }),
    );
  }

  return Promise.all(promises)
    .then(([headReport, baseReport = {}]) => {
      commit(types.RECEIVE_LOAD_LICENSE_REPORT, { headReport, baseReport });
    })
    .catch(error => {
      commit(types.RECEIVE_LOAD_LICENSE_REPORT_ERROR, error);
    });
};

export const setLicenseApproval = ({ commit, dispatch, state }, payload) => {
  const { apiUrlManageLicenses } = state;
  const { license, newStatus } = payload;
  const { id, name } = license;

  commit(types.REQUEST_SET_LICENSE_APPROVAL);

  let request;

  /*
   Licenses that have an ID, are already in the database.
   So we need to send PATCH instead of POST.
   */
  if (id) {
    request = axios.patch(`${apiUrlManageLicenses}/${id}`, { approval_status: newStatus });
  } else {
    request = axios.post(apiUrlManageLicenses, { approval_status: newStatus, name });
  }

  return request
    .then(() => {
      commit(types.RECEIVE_SET_LICENSE_APPROVAL);
      dispatch('loadManagedLicenses');
    })
    .catch(error => {
      commit(types.RECEIVE_SET_LICENSE_APPROVAL_ERROR, error);
    });
};
export const approveLicense = ({ dispatch }, license) => {
  const { approvalStatus } = license;
  if (approvalStatus !== LICENSE_APPROVAL_STATUS.APPROVED) {
    dispatch('setLicenseApproval', { license, newStatus: LICENSE_APPROVAL_STATUS.APPROVED });
  }
};

export const blacklistLicense = ({ dispatch }, license) => {
  const { approvalStatus } = license;
  if (approvalStatus !== LICENSE_APPROVAL_STATUS.BLACKLISTED) {
    dispatch('setLicenseApproval', { license, newStatus: LICENSE_APPROVAL_STATUS.BLACKLISTED });
  }
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
