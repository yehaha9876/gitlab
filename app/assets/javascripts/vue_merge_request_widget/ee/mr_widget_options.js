import CEWidgetOptions from '../mr_widget_options';
import { WidgetApprovals } from '../dependencies';

const EEWidgetOptions = Object.assign({}, CEWidgetOptions);
const EEComponents = { 'mr-widget-approvals': WidgetApprovals };
const EETemplate = `
    <div class="mr-state-widget prepend-top-default">
      <mr-widget-header :mr="mr" />
      <mr-widget-pipeline v-if="shouldRenderPipelines" :mr="mr" />
      <mr-widget-deployment v-if="shouldRenderDeployments" :mr="mr" :service="service" />
      <mr-widget-approvals :mr='mr' :service='service'/>
      <component :is="componentName" :mr="mr" :service="service" />
      <mr-widget-related-links v-if="shouldRenderRelatedLinks" :related-links="mr.relatedLinks" />
      <mr-widget-merge-help v-if="shouldRenderMergeHelp" />
    </div>
  `;

const EEComputed = {
  shouldRenderApprovals() {
    return this.mr.approvalsRequired;
  },
};

Object.assign(EEWidgetOptions.components, EEComponents);

EEWidgetOptions.template = EETemplate;

Object.assign(EEWidgetOptions.computed, EEComputed);

export default EEWidgetOptions;
