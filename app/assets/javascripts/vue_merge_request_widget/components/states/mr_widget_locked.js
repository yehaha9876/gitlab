import ciIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  name: 'MRWidgetLocked',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    ciIcon,
  },
  template: `
    <div class="mr-widget-body mr-state-locked media">
      <ci-icon :status="{ group: 'pending', icon: 'icon_status_pending' }" />
      <div class="media-body">
        <h4>
          This merge request is in the process of being merged, during which time it is locked and cannot be closed
          <i
            class="fa fa-spinner fa-spin"
            aria-hidden="true" />
        </h4>
        <section class="mr-info-list">
          <p>
            The changes will be merged into
            <span class="label-branch">
              <a :href="mr.targetBranchPath">{{mr.targetBranch}}</a>
            </span>.
          </p>
        </section>
      </div>
    </div>
  `,
};
