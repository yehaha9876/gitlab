/* eslint-disable no-new */

import initShow from '~/pages/projects/issues/show';
import initSidebarBundle from 'ee/sidebar/sidebar_bundle';
import initRelatedIssues from 'ee/related_issues';
import UserCallout from '~/user_callout';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  initSidebarBundle();
  initRelatedIssues();
  new UserCallout({ className: 'js-epics-sidebar-callout' });
});
