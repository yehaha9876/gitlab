export default {
  name: 'IssueCardUser',
  props: {
    assignee: { type: Object, required: true },
    rootPath: { type: String, required: true },
  },
  template: `
    <a
      class="card-assignee has-tooltip js-no-trigger"
      :href="rootPath + assignee.username"
      :title="'Assigned to ' + assignee.name"
      data-container="body">
      <img
        class="avatar avatar-inline s20 js-no-trigger"
        :src="assignee.avatar"
        width="20"
        height="20"
        :alt="'Avatar for ' + assignee.name" />
    </a>
  `,
};