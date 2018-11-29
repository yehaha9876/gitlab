import mountInstanceLicenseApp from 'ee/instance_licenses';

document.addEventListener('DOMContentLoaded', () => {
  const mountElement = document.getElementById('instance-license-mount-element');
  mountInstanceLicenseApp(mountElement);
});
