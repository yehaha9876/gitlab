import CePipelineMediator from '~/pipelines/pipeline_details_mediator';

/**
 * Extends CE mediator with the logic to handle the upstream/downstream pipelines
 */
export default class EePipelineMediator extends CePipelineMediator {
  resetPipeline(storeKey, pipeline, resetStoreKey) {
    this.store.closePipeline(storeKey, pipeline, resetStoreKey);
  }
}
