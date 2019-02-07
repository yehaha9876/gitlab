import ceState from '~/environments/stores/state';
import { parseBoolean } from '~/lib/utils/common_utils';

export default environmentsData => ({
  ...ceState(environmentsData),
  canaryDeploymentFeatureId: environmentsData.environmentsDataCanaryDeploymentFeatureId,
  showCanaryDeploymentCallout: parseBoolean(
    environmentsData.environmentsDataShowCanaryDeploymentCallout,
  ),
  userCalloutsPath: environmentsData.environmentsDataUserCalloutsPath,
  lockPromotionSvgPath: environmentsData.environmentsDataLockPromotionSvgPath,
  helpCanaryDeploymentsPath: environmentsData.environmentsDataHelpCanaryDeploymentsPath,
});
