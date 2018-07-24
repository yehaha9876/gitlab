import Vue from 'vue';
import _ from 'underscore';
import { __ } from '~/locale';
import Flash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import ListContainer from './list_container.vue';

export default Vue.extend({
  components: {
    ListContainer,
  },
  props: {
    listPath: {
      type: String,
      required: true,
    },
    listType: {
      type: String,
      required: true,
    },
    listItemComponent: {
      type: Object,
      required: true,
    },
    filterItems: {
      type: Function,
      required: true,
    },
    onItemSelect: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      store: gl.issueBoards.BoardsStore,
    };
  },
  mounted() {
    this.loadList();
  },
  methods: {
    loadList() {
      if (this.store.state[this.listType].length) {
        return Promise.resolve();
      }

      return axios
        .get(this.listPath)
        .then(({ data }) => {
          this.loading = false;
          this.store.state[this.listType] = data;
        })
        .catch(() => {
          this.loading = false;
          Flash(__(`Something went wrong while fetching ${this.listType} list`));
        });
    },
    handleItemClick(item) {
      if (!this.store.findList('title', item.name)) {
        this.store.new({
          title: item.name,
          position: this.store.state.lists.length - 2,
          list_type: this.listType,
          user: item,
        });

        this.store.state.lists = _.sortBy(this.store.state.lists, 'position');
      }
    },
  },
  render(createElement) {
    return createElement('list-container', {
      props: {
        loading: this.loading,
        items: this.store.state[this.listType],
        filterItems: this.filterItems,
        listItemComponent: this.listItemComponent,
      },
      on: {
        onItemSelect: this.onItemSelect,
      },
    });
  },
});
