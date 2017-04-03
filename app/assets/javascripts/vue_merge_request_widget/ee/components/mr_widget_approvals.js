import ApprovalsBody from '~/merge_request_widget/approvals/components/approvals_body';
import ApprovalsFooter from '~/merge_request_widget/approvals/components/approvals_footer';

export default {
  name: 'ApprovalsMain',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  data() {
    return {
      fetchingApprovals: true,
    };
  },
  components: {
    'approvals-body': ApprovalsBody,
    'approvals-footer': ApprovalsFooter,
  },
  created() {
    this.service.fetchApprovals()
      .then(res => this.mr.setApprovals(res.data))
      .then(() => {
        this.fetchingApprovals = false;
      });
  },
  template: `
    <div class='mr-widget-approvals' v-if='mr.approvalsRequired'>
      <div class='mr-approvals-footer' v-show='fetchingApprovals'> 
        <i class='fa fa-spinner fa-spin'/>
        <span> Checking approval status for this merge request. </span>
      </div>
      <div class='approvals-components' v-if='!fetchingApprovals'>
        <approvals-body
          :service='service'
          :user-can-approve='mr.approvals.user_can_approve'
          :user-has-approved='mr.approvals.user_has_approved'
          :approved-by='mr.approvals.approved_by'
          :approvals-left='mr.approvals.approvals_left'
          :suggested-approvers='mr.approvals.suggested_approvers'/>
        <approvals-footer
          :service='service'
          :user-can-approve='mr.approvals.user_can_approve'
          :user-has-approved='mr.approvals.user_has_approved'
          :approved-by='mr.approvals.approved_by'
          :approvals-left='mr.approvals.approvals_left'/>
      </div>
    </div>
    `,
};

