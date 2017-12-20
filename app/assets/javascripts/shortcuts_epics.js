/* eslint-disable class-methods-use-this */
/* global Mousetrap */

import _ from 'underscore';
import 'mousetrap';
import ShortcutsNavigation from './shortcuts_navigation';
import findAndFollowLink from './shortcuts_dashboard_navigation';

export default class ShortcutsEpics extends ShortcutsNavigation {
  constructor() {
    super();
    Mousetrap.bind('e', () => ShortcutsEpics.editEpic());
    Mousetrap.bind('shift+=', () => ShortcutsEpics.addIssue());

    this.enabledHelp.push('.hidden-shortcut.epics');
  }

  static editEpic() {
    document.querySelector('.js-edit-epic').click();
  }

  static addIssue() {
    document.querySelector('.js-issue-count-badge-add-button').click();
  }
}
