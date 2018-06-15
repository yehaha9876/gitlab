import Vue from 'vue';
import { mapActions, mapState, mapGetters } from 'vuex';
import JobMediator from './job_details_mediator';
import jobHeader from './components/header.vue';
import detailsBlock from './components/sidebar_details_block.vue';
import seleniumCiView from '../selenium_ci_view/components/selenium_ci_view.vue';
import seleniumCiViewStore from '../selenium_ci_view/store';

export default () => {
  const { dataset } = document.getElementById('js-job-details-vue');
  const mediator = new JobMediator({ endpoint: dataset.endpoint });

  mediator.fetchJob();

  // Header
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-build-header-vue',
    components: {
      jobHeader,
    },
    data() {
      return {
        mediator,
      };
    },
    mounted() {
      this.mediator.initBuildClass();
    },
    render(createElement) {
      return createElement('job-header', {
        props: {
          isLoading: this.mediator.state.isLoading,
          job: this.mediator.store.state.job,
        },
      });
    },
  });

  // Sidebar information block
  const detailsBlockElement = document.getElementById('js-details-block-vue');
  const detailsBlockDataset = detailsBlockElement.dataset;
  // eslint-disable-next-line
  new Vue({
    el: detailsBlockElement,
    components: {
      detailsBlock,
    },
    data() {
      return {
        mediator,
      };
    },
    render(createElement) {
      return createElement('details-block', {
        props: {
          isLoading: this.mediator.state.isLoading,
          job: this.mediator.store.state.job,
          runnerHelpUrl: dataset.runnerHelpUrl,
          terminalPath: detailsBlockDataset.terminalPath,
        },
      });
    },
  });

  const seleniumViewElement = document.getElementById('js-selenium-view-app');
  if (seleniumViewElement) {
    // eslint-disable-next-line
    new Vue({
      el: seleniumViewElement,
      store: seleniumCiViewStore,
      components: {
        seleniumCiView,
      },
      computed: {
        ...mapState([
          //'todo',
        ]),
        ...mapGetters([
          'firstSessionId',
        ]),
      },
      created() {
        const seleniumViewDataset = seleniumViewElement.dataset;
        console.log('seleniumViewDataset', seleniumViewDataset);

        this.setBaseArtifactEndpoint(seleniumViewDataset.baseArtifactEndpoint);
        this.setSessionIds((seleniumViewDataset.sessionIds || '').split(','));

        this.fetchSessionLog(this.firstSessionId);
      },
      methods: {
        ...mapActions([
          'setBaseArtifactEndpoint',
          'setSessionIds',
          'fetchSessionLog',
        ]),
      },
      render(createElement) {
        return createElement('selenium-ci-view', {
          props: {
            // ...
          },
        });
      },
    });
  }
};
