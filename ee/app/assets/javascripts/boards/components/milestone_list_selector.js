import _ from 'underscore';
import $ from 'jquery';
import BoardsListSelector from './boards_list_selector';
import MilestoneListItem from './boards_list_selector/milestones_list_item.vue';

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

const Store = gl.issueBoards.BoardsStore;

export default function () {
  const $addListEl = $('#js-add-list');

  return new BoardsListSelector({
    propsData: {
      listPath: $addListEl.find('.js-new-board-list').data('listMilestonePath'),
      listType: 'milestones',
      filterItems: (term, items) => {
        const query = term.toLowerCase();
        return items.filter((item) => {
          const name = item.title.toLowerCase();
          return name.indexOf(query) > -1;
        });
      },
      onItemSelect: (item) => {
        if (!Store.findList('title', item.title)) {
          Store.new({
            title: item.title,
            position: Store.state.lists.length - 2,
            list_type: 'milestones',
            milestone: item,
          });

          Store.state.lists = _.sortBy(Store.state.lists, 'position');
        }
      },
      listItemComponent: MilestoneListItem,
    },
  }).$mount('.js-milestone-list');
}
