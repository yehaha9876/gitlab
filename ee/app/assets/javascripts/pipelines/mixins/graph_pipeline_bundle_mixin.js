import pipelinesKeys from 'ee/pipelines/constants';

export default {
  methods: {
    /**
     * Called when a linked pipeline is clicked.
     *
     * If the pipeline is collapsed we will start polling it & we will reset the other pipelines.
     * If the pipeline is expanded we will close it.
     *
     * @param {String} method Method to fetch the pipeline
     * @param {String} storeKey Store property that will be updates
     * @param {String} resetStoreKey Store key for the visible pipeline that will need to be reset
     * @param {Object} pipeline The clicked pipeline
     */
    // clickPipeline(method, storeKey, resetStoreKey, pipeline, pollKey) {
    //   if (pipeline.isCollapsed) {
    //     this.mediator[method](pipeline);
    //   } else {
    //     this.mediator.resetPipeline(storeKey, pipeline, resetStoreKey, pollKey);
    //   }
    // },
    clickTriggered(triggered) {
      this.clickPipeline(
        'fetchTriggeredPipeline',
        pipelinesKeys.triggeredPipelines,
        pipelinesKeys.triggered,
        triggered,
        'pollTriggered',
      );
    },
    clickTriggeredBy(triggeredBy) {
      this.clickPipeline(
        'fetchTriggeredByPipeline',
        pipelinesKeys.triggeredByPipelines,
        pipelinesKeys.triggeredBy,
        triggeredBy,
        'pollTriggeredBy',
      );
    },
    clickPipeline(key, parentId, pipeline) {
      // find pipeline in upstream or

      // if it's collpased, let's expand it
      if (pipeline.isCollapsed) {
        this.store.expandPipeline(key, parentId, pipeline);
      } else {
        // otherwise let's reset it
        this.store.closePipeline(key, parentId, pipeline);
      }
    },
  },
};
