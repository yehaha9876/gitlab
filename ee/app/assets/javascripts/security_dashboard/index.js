import Vue from 'vue';
import GroupSecurityDashboardApp from './components/app.vue';
import UnavailableState from './components/unavailable_state.vue';
import createStore from './store';
import router from './store/router';

function createInstance({ el, components, name, props }) {
  const store = createStore();

  return new Vue({
    el,
    store,
    router,
    components,
    render(createElement) {
      return createElement(name, { props });
    },
  });
}

export default () => {
  let el = document.getElementById('js-group-security-dashboard-unavailable');
  let components;
  let props;
  let name;

  if (el) {
    components = { UnavailableState };
    name = 'unavailable-state';
    props = {
      link: el.dataset.dashboardDocumentation,
      svgPath: el.dataset.emptyStateSvgPath,
    };
  } else {
    el = document.getElementById('js-group-security-dashboard');
    components = { GroupSecurityDashboardApp };
    name = 'group-security-dashboard-app';
    props = {
      dashboardDocumentation: el.dataset.dashboardDocumentation,
      emptyStateSvgPath: el.dataset.emptyStateSvgPath,
      projectsEndpoint: el.dataset.projectsEndpoint,
      vulnerabilityFeedbackHelpPath: el.dataset.vulnerabilityFeedbackHelpPath,
      vulnerabilitiesEndpoint: el.dataset.vulnerabilitiesEndpoint,
      vulnerabilitiesCountEndpoint: el.dataset.vulnerabilitiesSummaryEndpoint,
      vulnerabilitiesHistoryEndpoint: el.dataset.vulnerabilitiesHistoryEndpoint,
    };
  }

  return createInstance({ el, components, name, props });
};
