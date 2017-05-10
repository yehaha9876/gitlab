/* global Flash */
import pendingAvatarSvg from 'icons/_icon_dotted_circle.svg';
import UserAvatarLink from '../../../../vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarSvg from '../../../../vue_shared/components/user_avatar/user_avatar_svg.vue';
import eventHub from '../../../event_hub';

export default {
  name: 'approvals-footer',
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
      unapproving: false,
      pendingAvatarSvg,
    };
  },
  components: {
    'user-avatar-link': UserAvatarLink,
    'user-avatar-svg': UserAvatarSvg,
  },
  computed: {
    showUnapproveButton() {
      return this.userHasApproved && !this.userCanApprove;
    },
  },
  methods: {
    unapproveMergeRequest() {
      this.unapproving = true;
      this.service.unapproveMergeRequest()
        .then((data) => {
          this.mr.setApprovals(data);
          eventHub.$emit('MRWidgetUpdateRequested');
          this.unapproving = false;
        })
        .catch(() => {
          this.unapproving = false;
          new Flash('An error occured while removing your approval.'); // eslint-disable-line
        });
    },
  },
  template: `
    <div v-if="approvedBy.length" class="approved-by-users approvals-footer clearfix mr-info-list">
      <div class="legend"></div>
      <div>
        <p class="approvers-prefix">Approved by</p>
        <div class="approvers-list">
          <span v-for="approver in approvedBy">
            <user-avatar-link
              class="approver-avatar"
              :href="approver.user.web_url"
              :img-src="approver.user.avatar_url"
              :img-size="18"
              :tooltip-text="approver.user.name"
            />
          </span>
          <span class="potential-approvers-list">
            <user-avatar-svg
              v-for="n in approvalsLeft"
              class="hide-asset"
              :svg="pendingAvatarSvg"
              :size="18"
            />
          </span>
        </div>
        <span class="unapprove-btn-wrap" v-if="showUnapproveButton">
          <button
            :disabled="unapproving"
            @click="unapproveMergeRequest"
            class="btn btn-sm">
            <i
              v-if="unapproving"
              class="fa fa-spinner fa-spin"
              aria-hidden="true" />
            Remove your approval
          </button>
        </span>
      </div>
    </div>
  `,
};
