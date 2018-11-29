<template>
  <div class="card instance-license-card">
    <div class="card-header d-flex justify-content-between align-items-center">
      <h4>
        {{
          sprintf(__('GitLab Enterprise Edition %{plan}'), {
            plan: capitalizeFirstCharacter(license.plan),
          })
        }}
      </h4>
      <gl-dropdown right :text="__('Manage')" :disabled="isLoading">
        <gl-dropdown-item>{{ __('Download license') }}</gl-dropdown-item>
        <gl-dropdown-item class="text-danger" @click="deleteLicense">
          {{ __('Delete license') }}
        </gl-dropdown-item>
      </gl-dropdown>
    </div>

    <div class="card-body license-card-body p-0">
      <div
        v-if="isLoading"
        class="d-flex justify-content-center align-items-center license-card-loading"
      >
        <icon name="spinner" /><span class="ml-2">{{ __('Removing license…') }}</span>
      </div>
      <div class="license-table" v-else>
        <div class="license-table-row d-flex">
          <header-cell :title="__('Usage')" icon="monitor" />
          <cell :title="__('Seats in license')" :value="license.restrictedUserCount" />
          <info-cell
            :title="__('Seats currently in use')"
            :value="license.currentActiveUsersCount"
            :popover-title="info.currentActiveUsersCount"
          />
          <info-cell
            :title="__('Max seats used')"
            :value="license.historicalMax"
            :popover-title="info.historicalMax"
          >
            <gl-link href="https://about.gitlab.com/pricing/licensing-faq/" target="_blank">{{
              __('Learn more about renewals')
            }}</gl-link>
          </info-cell>
          <info-cell
            :title="__('Users outside of license')"
            :value="license.overage"
            :popover-title="info.overage"
          >
            <gl-link href="https://about.gitlab.com/pricing/licensing-faq/" target="_blank">{{
              __('Learn more about the true-up model')
            }}</gl-link>
          </info-cell>
        </div>
        <div class="license-table-row d-flex">
          <header-cell :title="__('Validity')" icon="calendar" />
          <cell :title="__('Start date')" :value="license.startsAt" />
          <expirable-cell :title="__('End date')" :value="license.expiresAt" />
          <cell :title="__('Uploaded on')" :value="license.createdAt" />
        </div>
        <div class="license-table-row d-flex">
          <header-cell :title="__('Registration')" icon="user" />
          <cell :title="__('Licensed to')" :value="license.licensee.name" />
          <cell :title="__('Email address')" :value="license.licensee.email" />
          <cell :title="__('Company')" :value="license.licensee.company" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { GlLink, GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import Icon from '~/vue_shared/components/icon.vue';
import createFlash from '~/flash';
import Cell from './instance_licenses_table/cell.vue';
import HeaderCell from './instance_licenses_table/header_cell.vue';
import InfoCell from './instance_licenses_table/info_cell.vue';
import ExpirableCell from './instance_licenses_table/expirable_cell.vue';
import licenseDelete from '../mutations/license_delete.graphql';
import licenses from '../queries/licenses.graphql';

// SHARE PLS
const DEFAULT_LICENSES_COUNT = 5;
const DEFAULT_CURSOR = '';

export default {
  name: 'InstanceLicenseCard',
  props: {
    license: {
      type: Object,
      required: true,
    },
  },
  components: {
    Icon,
    Cell,
    HeaderCell,
    InfoCell,
    ExpirableCell,
    GlLink,
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  data() {
    return {
      isLoading: false,
      info: {
        currentActiveUsersCount: this.__(
          "Users with a Guest role or those who don't belong to any projects or groups don't count towards seats in use.",
        ),
        historicalMax: this
          .__(`This is the maximum number of users that have existed at the same time since the license started.
              This is the minimum number of seats you will need to buy when you renew your license.`),
        overage: this
          .__(`GitLab allows you to continue using your license even if you exceed the number of seats you purchased.
              You will be required to pay for these seats when you renew your license.`),
      },
    };
  },
  methods: {
    capitalizeFirstCharacter: capitalizeFirstCharacter,
    deleteLicense() {
      if (this.isLoading) return;
      this.isLoading = true;

      this.$apollo
        .mutate({
          mutation: licenseDelete,
          variables: {
            input: {
              id: this.license.id,
            },
          },
          update(store, { data }) {
            const queryData = store.readQuery({
              query: licenses,
              variables: { first: DEFAULT_LICENSES_COUNT, after: DEFAULT_CURSOR },
            });
            const licenseIndex = queryData.licenses.edges.findIndex(
              license => license.node.id === data.licenseDelete.license.id,
            );
            queryData.licenses.edges.splice(licenseIndex, 1);
            store.writeQuery({
              query: licenses,
              variables: { first: DEFAULT_LICENSES_COUNT, after: DEFAULT_CURSOR },
              data: queryData,
            });
          },
        })
        .then(() => (this.isLoading = false))
        .catch(() => {
          this.isLoading = false;
          createFlash(__('An error occurred while deleting license'));
        });
    },
  },
};
</script>
