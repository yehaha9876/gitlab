import state from 'ee/environments/stores/state';

describe('ee environments store state', () => {
  const dataset = {
    canaryDeploymentFeatureId: 'canary_deployment',
    showCanaryDeploymentCallout: false,
    userCalloutsPath: 'http://test.host/-/user_callouts',
    lockPromotionSvgPath:
      'http://test.host/assets/illustrations/lock_promotion-bd924fa00ce403a678a0686bf3a633a20eeeddc1f945d1ac81bc3cc9b69d4036.svg',
    helpCanaryDeploymentsPath: 'http://test.host/help/user/project/canary_deployments',
  };

  describe('initial state for environments app', () => {
    let initialState;

    beforeEach(() => {
      loadFixtures('projects/environments/app.html.raw');
      initialState = state(document.getElementById('environments-list-view').dataset);
    });

    it('sets canaryDeploymentFeatureId', () => {
      expect(initialState.canaryDeploymentFeatureId).toBe(dataset.canaryDeploymentFeatureId);
    });

    it('sets showCanaryDeploymentCallout', () => {
      expect(initialState.showCanaryDeploymentCallout).toBe(dataset.showCanaryDeploymentCallout);
    });

    it('sets userCalloutsPath', () => {
      expect(initialState.userCalloutsPath).toBe(dataset.userCalloutsPath);
    });

    it('sets lockPromotionSvgPath', () => {
      expect(initialState.lockPromotionSvgPath).toBe(dataset.lockPromotionSvgPath);
    });

    it('sets helpCanaryDeploymentsPath', () => {
      expect(initialState.helpCanaryDeploymentsPath).toBe(dataset.helpCanaryDeploymentsPath);
    });
  });

  describe('initial state for environments folder view', () => {
    let initialState;

    beforeEach(() => {
      loadFixtures('projects/environments/folder.html.raw');
      initialState = state(document.getElementById('environments-folder-list-view').dataset);
    });

    it('sets canaryDeploymentFeatureId', () => {
      expect(initialState.canaryDeploymentFeatureId).toBe(dataset.canaryDeploymentFeatureId);
    });

    it('sets showCanaryDeploymentCallout', () => {
      expect(initialState.showCanaryDeploymentCallout).toBe(dataset.showCanaryDeploymentCallout);
    });

    it('sets userCalloutsPath', () => {
      expect(initialState.userCalloutsPath).toBe(dataset.userCalloutsPath);
    });

    it('sets lockPromotionSvgPath', () => {
      expect(initialState.lockPromotionSvgPath).toBe(dataset.lockPromotionSvgPath);
    });

    it('sets helpCanaryDeploymentsPath', () => {
      expect(initialState.helpCanaryDeploymentsPath).toBe(dataset.helpCanaryDeploymentsPath);
    });
  });
});
