import Chart from 'chart.js';
import Vue from 'vue';
import initGroupMemberContributions from 'ee/group_member_contributions';
import BarChart from '~/vue_shared/components/bar_chart.vue';

function getRandomArbitrary(min, max) {
  return Math.random() * (max - min) + min;
}

document.addEventListener('DOMContentLoaded', () => {
  const dataEl = document.getElementById('js-analytics-data');
  if (dataEl) {
    const data = JSON.parse(dataEl.innerHTML);
    const labels = data.labels;
    const outputElIds = ['push', 'issues_closed', 'merge_requests_created'];

    outputElIds.forEach((id) => {
      const el = document.getElementById(id);
      const ctx = el.getContext('2d');
      const chart = new Chart(ctx);

      chart.Bar({
        labels,
        datasets: [{
          fillColor: 'rgba(220,220,220,0.5)',
          strokeColor: 'rgba(220,220,220,1)',
          barStrokeWidth: 1,
          barValueSpacing: 1,
          barDatasetSpacing: 1,
          data: data[id].data,
        }],
      },
        {
          scaleOverlay: true,
          responsive: true,
          maintainAspectRatio: false,
        },
      );
    });

    initGroupMemberContributions();
    // TODO: change this for the actual data from the backend
    const dataForVue = data.labels.map((name, index) => ({
      name,
      // mergeRequestsCreated: data.merge_requests_created.data[index],
      value: parseInt(getRandomArbitrary(1, 8), 10),
    }));

    const el = document.getElementById('merge_requests_created_vue');
    // eslint-disable-next-line no-new
    new Vue({
      el,
      components: {
        BarChart,
      },
      render(createElement) {
        return createElement('bar-chart', { props: { graphData: dataForVue } });
      },
    });
  }
});
