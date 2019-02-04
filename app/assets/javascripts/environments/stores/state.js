import { parseBoolean } from '~/lib/utils/common_utils';

export default environmentsData => ({
  endpoint: environmentsData.environmentsDataEndpoint,
  newEnvironmentPath: environmentsData.newEnvironmentPath,
  helpPagePath: environmentsData.helpPagePath,
  cssContainerClass: environmentsData.cssClass,
  canCreateEnvironment: parseBoolean(environmentsData.canCreateEnvironment),
  canCreateDeployment: parseBoolean(environmentsData.canCreateDeployment),
  canReadEnvironment: parseBoolean(environmentsData.canReadEnvironment),
});
