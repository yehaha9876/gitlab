import CePipelineStore from '~/pipelines/stores/pipeline_store';
import mock from '../data.json';

/**
 * Extends CE store with the logic to handle the upstream/downstream pipelines
 */
export default class PipelineStore extends CePipelineStore {

  /**
   * For the triggered pipelines, parses them to add`isCollapsed` keys
   *
   * For the triggered_by pipeline, parses the object to add `isCollapsed` keys
   * and saves it as an array
   *
   * @param {Object} pipeline
   */
  storePipeline(pipeline = {}) {
    //todo remove
    pipeline = Object.assign({}, mock);

    if (pipeline.triggered_by) {
      Object.assign(pipeline, {
        triggered_by: [
          Object.assign({}, pipeline.triggered_by, {
            isCollapsed:
              this.state.pipeline.triggered_by && this.state.pipeline.triggered_by.length
                ? this.state.pipeline.triggered_by[0].isCollapsed
                : true,
          }),
        ],
      });
    }

    if (pipeline.triggered && pipeline.triggered.length) {
      Object.assign(pipeline, {
        triggered: pipeline.triggered.map(triggered => {
          const oldPipeline = this.state.pipeline.triggered && this.state.pipeline.triggered.find(
            oldValue => oldValue.id === triggered.id,
          );

          return Object.assign({}, triggered, {
            isCollapsed: oldPipeline ? oldPipeline.isCollapsed : true,
          });
        }),
      });
    }

    // todo - handle polling & formatting in nested upstreams & downstreams

    super.storePipeline(pipeline);
  }

  togglePipeline(key, parentId, pipeline) {
    // first level pipeline
    if (this.state.pipeline.id === parentId) {
      this.state.pipeline[key] = this.state.pipeline[key].map(el => {
        if (el.id === pipeline.id) {
          return Object.assign({}, pipeline, { isCollapsed: !pipeline.isCollapsed });
        }

        return PipelineStore.parsePipeline(pipeline);
      });
    } else {
      // we need to recursively find the pipeline
    }
  }

  /**
   * Adds isCollpased keys to the given pipeline
   *
   * Used to know when to render the blue background and when the pipeline is expanded.
   *
   * @param {Object} pipeline
   * @returns {Object}
   */
  static parsePipeline(pipeline) {
    return Object.assign({}, pipeline, {
      isCollapsed: true,
    });
  }
}
