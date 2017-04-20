import Vue from 'vue';
import VueResource from 'vue-resource';

import issuableTimeTracker from './components/time_tracker';
import '../../smart_interval';
import '../../subbable_resource';

Vue.use(VueResource);

export default {
  el: '#issuable-time-tracker',
  data: {
    issuable: {},
    docsUrl: '',
  },
  components: {
    'issuable-time-tracker': issuableTimeTracker,
  },
  methods: {
    fetchIssuable() {
      return gl.IssuableResource.get.call(gl.IssuableResource, {
        type: 'GET',
        url: gl.IssuableResource.endpoint,
      });
    },
    updateState(data) {
      this.issuable = data;
    },
    subscribeToUpdates() {
      gl.IssuableResource.subscribe(data => this.updateState(data));
    },
    listenForSlashCommands() {
      $(document).on('ajax:success', '.gfm-form', (e, data) => {
        const subscribedCommands = ['spend_time', 'time_estimate'];
        const changedCommands = data.commands_changes
          ? Object.keys(data.commands_changes)
          : [];
        if (changedCommands && _.intersection(subscribedCommands, changedCommands).length) {
          this.fetchIssuable();
        }
      });
    },
  },
  created() {
    this.fetchIssuable();
  },
  mounted() {
    this.subscribeToUpdates();
    this.listenForSlashCommands();
  },
  beforeMount() {
    const element = this.$el;
    this.docsUrl = element.dataset.docsUrl;
    this.issuable = JSON.parse(gl.IssuableTimeTracking);
  },
  template: `
    <div class="block">
      <issuable-time-tracker
        :time_estimate="issuable.time_estimate"
        :time_spent="issuable.total_time_spent"
        :human_time_estimate="issuable.human_time_estimate"
        :human_time_spent="issuable.human_time_spent"
        :docsUrl="docsUrl"
      />
    </div>
  `,
};
