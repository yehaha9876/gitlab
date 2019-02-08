import Vue from 'vue';
import GroupSecurityDashboardApp from './components/app.vue';
import UnavailableState from './components/unavailable_state.vue';
import createStore from './store';
import router from './store/router';

export default () => {
  let el = document.getElementById('js-group-security-dashboard-unavailable');

  if (el) {
    return new Vue({
      el,
      components: { UnavailableState },
      render(createElement) {
        return createElement('unavailable-state', { props: {
            link: el.dataset.dashboardDocumentation,
            svgPath: el.dataset.emptyStateSvgPath,
          } });
      },
    });
  }

  el = document.getElementById('js-group-security-dashboard')
  const store = createStore();
  return new Vue({
    el,
    store,
    router,
    components: { GroupSecurityDashboardApp },
    render(createElement) {
      return createElement('group-security-dashboard-app', { props: {
          dashboardDocumentation: el.dataset.dashboardDocumentation,
          emptyStateSvgPath: el.dataset.emptyStateSvgPath,
          projectsEndpoint: el.dataset.projectsEndpoint,
          vulnerabilityFeedbackHelpPath: el.dataset.vulnerabilityFeedbackHelpPath,
          vulnerabilitiesEndpoint: el.dataset.vulnerabilitiesEndpoint,
          vulnerabilitiesCountEndpoint: el.dataset.vulnerabilitiesSummaryEndpoint,
          vulnerabilitiesHistoryEndpoint: el.dataset.vulnerabilitiesHistoryEndpoint,
        } });
    }
  })



};
