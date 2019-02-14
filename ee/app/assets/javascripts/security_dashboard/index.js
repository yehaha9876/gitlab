import Vue from 'vue';
import GroupSecurityDashboardApp from './components/app.vue';
import UnavailableState from './components/unavailable_state.vue';
import createStore from './store';
import router from './store/router';

export default function() {
  const emptyStateElement = document.getElementById('js-group-security-dashboard-unavailable');

  if (emptyStateElement) {
    return new Vue({
      el: emptyStateElement,
      components: { UnavailableState },
      render(createElement) {
        return createElement('unavailable-state', {
          props: {
            link: emptyStateElement.dataset.dashboardDocumentation,
            svgPath: emptyStateElement.dataset.emptyStateSvgPath,
          },
        });
      },
    });
  }

  const dashboardElement = document.getElementById('js-group-security-dashboard');
  const store = createStore();
  return new Vue({
    el: dashboardElement,
    store,
    router,
    components: { GroupSecurityDashboardApp },
    render(createElement) {
      return createElement('group-security-dashboard-app', {
        props: {
          dashboardDocumentation: dashboardElement.dataset.dashboardDocumentation,
          emptyStateSvgPath: dashboardElement.dataset.emptyStateSvgPath,
          projectsEndpoint: dashboardElement.dataset.projectsEndpoint,
          vulnerabilityFeedbackHelpPath: dashboardElement.dataset.vulnerabilityFeedbackHelpPath,
          vulnerabilitiesEndpoint: dashboardElement.dataset.vulnerabilitiesEndpoint,
          vulnerabilitiesCountEndpoint: dashboardElement.dataset.vulnerabilitiesSummaryEndpoint,
          vulnerabilitiesHistoryEndpoint: dashboardElement.dataset.vulnerabilitiesHistoryEndpoint,
        },
      });
    },
  });
}
