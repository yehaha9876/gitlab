import CEWidgetOptions from '../mr_widget_options';
import { WidgetApprovals } from '../dependencies';

export default {
  extends: CEWidgetOptions,
  components: {
    'mr-widget-approvals': WidgetApprovals,
  },
  computed: {
    shouldRenderApprovals() {
      return this.mr.approvalsRequired;
    },
  },
  template: `
    <div class="mr-state-widget prepend-top-default">
      <mr-widget-header :mr="mr" />
      <mr-widget-pipeline v-if="shouldRenderPipelines" :mr="mr" />
      <mr-widget-deployment v-if="shouldRenderDeployments" :mr="mr" :service="service" />
      <component :is="componentName" :mr="mr" :service="service" />
      <mr-widget-related-links v-if="shouldRenderRelatedLinks" :related-links="mr.relatedLinks" />
      <mr-widget-approvals :mr='mr' :service='service'/>
      <mr-widget-merge-help v-if="shouldRenderMergeHelp" />
    </div>
  `,
};
