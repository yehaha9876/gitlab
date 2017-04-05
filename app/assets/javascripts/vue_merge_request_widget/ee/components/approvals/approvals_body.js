export default {
  name: 'approvals-body',
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
    approvedBy: {
      type: Array,
      required: false,
    },
    approvalsLeft: {
      type: Number,
      required: false,
    },
    userCanApprove: {
      type: Boolean,
      required: false,
    },
    userHasApproved: {
      type: Boolean,
      required: false,
    },
    suggestedApprovers: {
      type: Array,
      required: false,
    },
  },
  data() {
    return {
      approving: false,
    };
  },
  computed: {
    approvalsRequiredStringified() {
      const baseString = `${this.approvalsLeft} more approval`;
      return this.approvalsLeft === 1 ? baseString : `${baseString}s`;
    },
    approverNamesStringified() {
      const approvers = this.suggestedApprovers;

      if (!approvers) {
        return '';
      }

      return approvers.length === 1 ? approvers[0].name :
        approvers.reduce((memo, curr, index) => {
          const nextMemo = `${memo}${curr.name}`;

          if (index === approvers.length - 2) { // second to last index
            return `${nextMemo} or `;
          } else if (index === approvers.length - 1) { // last index
            return nextMemo;
          }

          return `${nextMemo}, `;
        }, '');
    },
    showApproveButton() {
      return this.userCanApprove && !this.userHasApproved;
    },
    showSuggestedApprovers() {
      return this.suggestedApprovers && this.suggestedApprovers.length;
    },
  },
  methods: {
    approveMergeRequest() {
      const flashErrorMessage = 'An error occured while submitting your approval.';

      this.approving = true;
      this.service.approveMergeRequest()
        .then((res) => {
          this.mr.setApprovals(res.data);
          this.approving = false;
        })
        .catch(() => new Flash(flashErrorMessage));
    },
  },
  template: `
    <div class='approvals-body mr-widget-footer mr-approvals-footer'>
      <h4> Requires {{ approvalsRequiredStringified }}
        <span v-if='showSuggestedApprovers'> (from {{ approverNamesStringified }}) </span>
      </h4>
      <div v-if='showApproveButton' class='append-bottom-10'>
        <button
          :disabled='approving'
          @click='approveMergeRequest'
          class='btn btn-primary approve-btn'>
          Approve Merge Request
        </button>
      </div>
    </div>
  `,
};
