import IssueCardUser from './issue_card_user';
import IssueCardUserCounter from './issue_card_user_counter';

export default {
  name: 'IssueCardMultipleUsers',
  props: {
    issue: { type: Object, required: true },
    rootPath: { type: String, required: true },
  },
  computed: {
    renderCount() {
      return this.issue.assignees.length > 3;
    },
    counter() {
      return this.issue.assignees.length - 3;
    },
  },
  components: {
    'issue-card-user': IssueCardUser,
    'issue-card-user-counter': IssueCardUserCounter,
  },
  template: `
    <span>
      <issue-card-user
        v-for="(assignee, index) in issue.assignees"
        v-if="index < 3"
        :key="assignee.username"
        :assignee="assignee"
        :rootPath="rootPath"
      />
      <issue-card-user-counter
        v-if="renderCount"
        :count="counter"
      />
    </span>
  `,
};