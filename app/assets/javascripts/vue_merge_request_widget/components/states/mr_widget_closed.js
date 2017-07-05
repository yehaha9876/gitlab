import mrWidgetAuthorTime from '../../components/mr_widget_author_time';
import ciIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  name: 'MRWidgetClosed',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'mr-widget-author-and-time': mrWidgetAuthorTime,
    ciIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <ci-icon :status="{ group: 'failed', icon: 'icon_status_failed' }" />
      <div class="media-body">
        <mr-widget-author-and-time
          actionText="Closed by"
          :author="mr.closedBy"
          :dateTitle="mr.updatedAt"
          :dateReadable="mr.closedAt"
        />
        <section class="mr-info-list">
          <p>
            The changes were not merged into
            <a
              :href="mr.targetBranchPath"
              class="label-branch">
              {{mr.targetBranch}}</a>.
          </p>
        </section>
      </div>
    </div>
  `,
};
