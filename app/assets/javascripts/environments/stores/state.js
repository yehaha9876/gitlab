import { parseBoolean } from '~/lib/utils/common_utils';

export default environmentsData => ({
  canCreateDeployment: parseBoolean(
    environmentsData.canCreateDeployment || environmentsData.environmentsDataCanCreateDeployment,
  ),
  canCreateEnvironment: parseBoolean(environmentsData.canCreateEnvironment),
  canReadEnvironment: parseBoolean(
    environmentsData.canReadEnvironment || environmentsData.environmentsDataCanReadEnvironment,
  ),
  cssContainerClass: environmentsData.cssClass,
  endpoint: environmentsData.environmentsDataEndpoint,
  folderName: environmentsData.environmentsDataFolderName,
  helpPagePath: environmentsData.helpPagePath,
  newEnvironmentPath: environmentsData.newEnvironmentPath,
});
