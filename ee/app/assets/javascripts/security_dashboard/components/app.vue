<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Tabs from '~/vue_shared/components/tabs/tabs';
import Tab from '~/vue_shared/components/tabs/tab.vue';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import SecurityDashboardTable from './security_dashboard_table.vue';
import VulnerabilityCountList from './vulnerability_count_list.vue';

export default {
  name: 'SecurityDashboardApp',
  components: {
    IssueModal,
    Tabs,
    Tab,
    SecurityDashboardTable,
    VulnerabilityCountList,
  },
  computed: {
    ...mapGetters('vulnerabilities', ['vulnerabilitiesCountByReportType']),
    ...mapState('vulnerabilities', ['modal']),
    sastCount() {
      return this.vulnerabilitiesCountByReportType('sast');
    },
  },
  created() {
    this.fetchVulnerabilitiesCount();
  },
  methods: {
    ...mapActions('vulnerabilities', ['fetchVulnerabilitiesCount']),
  },
};
</script>

<template>
  <div>
    <vulnerability-count-list />
    <tabs stop-propagation>
      <tab active>
        <template slot="title">
          {{ __('SAST') }}
          <span
            v-if="sastCount"
            class="badge badge-pill">
            {{ sastCount }}
          </span>
        </template>

        <security-dashboard-table/>
      </tab>
    </tabs>
    <issue-modal
      :modal="modal"
    />
  </div>
</template>

