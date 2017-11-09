import SmartInterval from '~/smart_interval';
import Flash from '../flash';
import {
  WidgetHeader,
  WidgetMergeHelp,
  WidgetPipeline,
  WidgetDeployment,
  WidgetRelatedLinks,
  MergedState,
  ClosedState,
  MergingState,
  WipState,
  ArchivedState,
  ConflictsState,
  NothingToMergeState,
  MissingBranchState,
  NotAllowedState,
  ReadyToMergeState,
  SHAMismatchState,
  UnresolvedDiscussionsState,
  PipelineBlockedState,
  PipelineFailedState,
  FailedToMerge,
  MergeWhenPipelineSucceedsState,
  AutoMergeFailed,
  CheckingState,
  MRWidgetStore,
  MRWidgetService,
  eventHub,
  stateMaps,
  SquashBeforeMerge,
  notify,
} from './dependencies';
import { setFavicon } from '../lib/utils/common_utils';

export default {
  el: '#js-vue-mr-widget',
  name: 'MRWidget',
  props: {
    mrData: {
      type: Object,
      required: false,
    },
  },
  data() {
    const store = new MRWidgetStore(this.mrData || window.gl.mrWidgetData);
    const service = this.createService(store);
    return {
      mr: store,
      service,
    };
  },
  computed: {
    componentName() {
      return stateMaps.stateToComponentMap[this.mr.state];
    },
    shouldRenderMergeHelp() {
      return stateMaps.statesToShowHelpWidget.indexOf(this.mr.state) > -1;
    },
    shouldRenderPipelines() {
      return this.mr.hasCI;
    },
    shouldRenderRelatedLinks() {
      return this.mr.relatedLinks;
    },
    shouldRenderDeployments() {
      return this.mr.deployments.length;
    },
  },
  methods: {
    createService(store) {
      const endpoints = {
        mergePath: store.mergePath,
        mergeCheckPath: store.mergeCheckPath,
        cancelAutoMergePath: store.cancelAutoMergePath,
        removeWIPPath: store.removeWIPPath,
        sourceBranchPath: store.sourceBranchPath,
        ciEnvironmentsStatusPath: store.ciEnvironmentsStatusPath,
        statusPath: store.statusPath,
        mergeActionsContentPath: store.mergeActionsContentPath,
        rebasePath: store.rebasePath,
        approvalsPath: store.approvalsPath,
      };
      return new MRWidgetService(endpoints);
    },
    checkStatus(cb) {
      return this.service.checkStatus()
        .then(res => res.json())
        .then((res) => {
          this.handleNotification(res);
          this.mr.setData(res);
          this.setFaviconHelper();

          if (cb) {
            cb.call(null, res);
          }
        })
        .catch(() => new Flash('Something went wrong. Please try again.'));
    },
    initPolling() {
      this.pollingInterval = new SmartInterval({
        callback: this.checkStatus,
        startingInterval: 10000,
        maxInterval: 30000,
        hiddenInterval: 120000,
        incrementByFactorOf: 5000,
      });
    },
    initDeploymentsPolling() {
      this.deploymentsInterval = new SmartInterval({
        callback: this.fetchDeployments,
        startingInterval: 30000,
        maxInterval: 120000,
        hiddenInterval: 240000,
        incrementByFactorOf: 15000,
        immediateExecution: true,
      });
    },
    setFaviconHelper() {
      if (this.mr.ciStatusFaviconPath) {
        setFavicon(this.mr.ciStatusFaviconPath);
      }
    },
    fetchDeployments() {
      return this.service.fetchDeployments()
        .then(res => res.json())
        .then((res) => {
          if (res.length) {
            this.mr.deployments = res;
          }
        })
        .catch(() => {
          new Flash('Something went wrong while fetching the environments for this merge request. Please try again.'); // eslint-disable-line
        });
    },
    fetchActionsContent() {
      this.service.fetchMergeActionsContent()
        .then((res) => {
          if (res.body) {
            const el = document.createElement('div');
            el.innerHTML = res.body;
            document.body.appendChild(el);
          }
        })
        .catch(() => new Flash('Something went wrong. Please try again.'));
    },
    handleNotification(data) {
      if (data.ci_status === this.mr.ciStatus) return;

      const label = data.pipeline.details.status.label;
      const title = `Pipeline ${label}`;
      const message = `Pipeline ${label} for "${data.title}"`;

      notify.notifyMe(title, message, this.mr.gitlabLogo);
    },
    resumePolling() {
      this.pollingInterval.resume();
    },
    stopPolling() {
      this.pollingInterval.stopTimer();
    },
    bindEventHubListeners() {
      eventHub.$on('MRWidgetUpdateRequested', (cb) => {
        this.checkStatus(cb);
      });

      // `params` should be an Array contains a Boolean, like `[true]`
      // Passing parameter as Boolean didn't work.
      eventHub.$on('SetBranchRemoveFlag', (params) => {
        this.mr.isRemovingSourceBranch = params[0];
      });

      eventHub.$on('FailedToMerge', (mergeError) => {
        this.mr.state = 'failedToMerge';
        this.mr.mergeError = mergeError;
      });

      eventHub.$on('UpdateWidgetData', (data) => {
        this.mr.setData(data);
      });

      eventHub.$on('FetchActionsContent', () => {
        this.fetchActionsContent();
      });

      eventHub.$on('EnablePolling', () => {
        this.resumePolling();
      });

      eventHub.$on('DisablePolling', () => {
        this.stopPolling();
      });
    },
    handleMounted() {
      this.setFaviconHelper();
      this.initDeploymentsPolling();
    },
  },
  created() {
    this.initPolling();
    this.bindEventHubListeners();
  },
  mounted() {
    this.handleMounted();
  },
  components: {
    'mr-widget-header': WidgetHeader,
    'mr-widget-merge-help': WidgetMergeHelp,
    'mr-widget-pipeline': WidgetPipeline,
    'mr-widget-deployment': WidgetDeployment,
    'mr-widget-related-links': WidgetRelatedLinks,
    'mr-widget-merged': MergedState,
    'mr-widget-closed': ClosedState,
    'mr-widget-merging': MergingState,
    'mr-widget-failed-to-merge': FailedToMerge,
    'mr-widget-wip': WipState,
    'mr-widget-archived': ArchivedState,
    'mr-widget-conflicts': ConflictsState,
    'mr-widget-nothing-to-merge': NothingToMergeState,
    'mr-widget-not-allowed': NotAllowedState,
    'mr-widget-missing-branch': MissingBranchState,
    'mr-widget-ready-to-merge': ReadyToMergeState,
    'mr-widget-sha-mismatch': SHAMismatchState,
    'mr-widget-squash-before-merge': SquashBeforeMerge,
    'mr-widget-checking': CheckingState,
    'mr-widget-unresolved-discussions': UnresolvedDiscussionsState,
    'mr-widget-pipeline-blocked': PipelineBlockedState,
    'mr-widget-pipeline-failed': PipelineFailedState,
    'mr-widget-merge-when-pipeline-succeeds': MergeWhenPipelineSucceedsState,
    'mr-widget-auto-merge-failed': AutoMergeFailed,
  },
  template: `
    <div class="mr-state-widget prepend-top-default">
      <mr-widget-header :mr="mr" />
      <mr-widget-pipeline
        v-if="shouldRenderPipelines"
        :pipeline="mr.pipeline"
        :ci-status="mr.ciStatus"
        :has-ci="mr.hasCI"
        />
      <mr-widget-deployment
        v-if="shouldRenderDeployments"
        :mr="mr"
        :service="service" />
      <div class="mr-widget-section">
        <component
          :is="componentName"
          :mr="mr"
          :service="service" />
        <mr-widget-related-links
          v-if="shouldRenderRelatedLinks"
          :state="mr.state"
          :related-links="mr.relatedLinks" />
      </div>
      <div
        class="mr-widget-footer"
        v-if="shouldRenderMergeHelp">
        <mr-widget-merge-help />
      </div>
    </div>
  `,
};
