import Mousetrap from 'mousetrap';
import _ from 'underscore';
import Sidebar from './right_sidebar';
import Shortcuts from './shortcuts';
import { CopyAsGFM } from './behaviors/copy_as_gfm';

export default class ShortcutsEpic extends Shortcuts {
  constructor() {
    super();

    Mousetrap.bind('e', ShortcutsEpic.editIssue);
    Mousetrap.bind('=', ShortcutsEpic.addIssuetoEpic);

  }

  static editIssue() {
    // Need to click the element as on issues, editing is inline
    // on merge request, editing is on a different page
    document.querySelector('.js-issuable-edit').click();

    return false;
  }

  static addIssuetoEpic() {
    document.querySelector('.js-issue-count-badge-add-button').click();

    return false;
  }
}
