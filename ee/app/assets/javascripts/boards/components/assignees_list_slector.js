import _ from 'underscore';
import $ from 'jquery';
import BoardsListSelector from './boards_list_selector/index';
import AssigneesListItem from './boards_list_selector/assignees_list_item.vue';

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

const Store = gl.issueBoards.BoardsStore;

export default function () {
  const $addListEl = $('#js-add-list');
  return new BoardsListSelector({
    propsData: {
      listPath: $addListEl.find('.js-new-board-list').data('listAssigneesPath'),
      listType: 'assignees',
      listItemComponent: AssigneesListItem,
      filterItems: (term, items) => {
        // fuzzaldrinPlus doesn't support filtering
        // on multiple keys hence we're using plain JS.
        const query = term.toLowerCase();
        return items.filter((item) => {
          const name = item.name.toLowerCase();
          const username = item.username.toLowerCase();

          return name.indexOf(query) > -1 || username.indexOf(query) > -1;
        });
      },
      onItemSelect: (item) => {
        if (!Store.findList('title', item.name)) {
          Store.new({
            title: item.name,
            position: Store.state.lists.length - 2,
            list_type: 'assignees',
            user: item,
          });

          Store.state.lists = _.sortBy(Store.state.lists, 'position');
        }
      },
    },
  }).$mount('.js-assignees-list');
}
