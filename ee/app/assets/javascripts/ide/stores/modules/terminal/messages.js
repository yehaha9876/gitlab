import _ from 'underscore';
import { __, sprintf } from '~/locale';
import httpStatus from '~/lib/utils/http_status';
import { WEB_IDE_JOB_TAG } from '../../../constants';

export const UNEXPECTED_ERROR_CHECK = __('An unexpected error occurred while checking the Web Terminal environment.');
export const UNEXPECTED_ERROR_STATUS = __('An unexpected error occurred while communicating with the Web Terminal.');
export const UNEXPECTED_ERROR_STARTING = __('An unexpected error occurred while starting the Web Terminal.');
export const UNEXPECTED_ERROR_STOPPING = __('An unexpected error occurred while stopping the Web Terminal.');
export const ERROR_RUNNERS = __('Configure GitLab runners to start using Web Terminal. %{helpStart}Learn more.%{helpEnd}');
export const ERROR_JOB = __('Add a <code>%{jobTag}</code> job in your <code>.gitlab-ci.yml</code> file to start using the Web Terminal. %{helpStart}Learn more.%{helpEnd}');
export const ERROR_PERMISSION = __('You do not have permission to run the Web Terminal. Please contact a project administrator.');

export const configCheckError = (status, helpUrl) => {
  if (status === httpStatus.UNPROCESSABLE_ENTITY) {
    return sprintf(
      ERROR_JOB,
      {
        jobTag: WEB_IDE_JOB_TAG,
        helpStart: `<a href="${_.escape(helpUrl)}" target="_blank">`,
        helpEnd: '</a>',
      },
      false,
    );
  } else if (status === httpStatus.FORBIDDEN) {
    return ERROR_PERMISSION;
  }

  return UNEXPECTED_ERROR_CHECK;
};

export const runnersCheckError = (helpUrl) =>
  sprintf(
    ERROR_RUNNERS,
    {
      helpStart: `<a href="${_.escape(helpUrl)}" target="_blank">`,
      helpEnd: '</a>',
    },
    false,
  );
