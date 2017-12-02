/* eslint-disable class-methods-use-this */
/* global Mousetrap */

import _ from 'underscore';
import 'mousetrap';
import ShortcutsNavigation from './shortcuts_navigation';
import findAndFollowLink from './shortcuts_dashboard_navigation';

export default class ShortcutsEpics extends ShortcutsNavigation {
  constructor() {
    super();
    Mousetrap.bind('e', this.editEpic);
    Mousetrap.bind('=', this.addIssue);

    this.enabledHelp.push('.hidden-shortcut.epics');
  }

  editEpic() {
    document.querySelector('.btn-edit').click();
    
    return false;
  }

  addIssue() {
    document.querySelector('.js-issue-count-badge-add-button').click();

    return false;
  }
}
