import KubernetesLogs from '../../../../kubernetes_logs';

document.addEventListener('DOMContentLoaded', () => {
  const kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');
  // eslint-disable-next-line no-new
  new KubernetesLogs(kubernetesLogContainer);
});
