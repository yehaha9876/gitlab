export default {
  data() {
    return {
      triggeredTopIndex: 1,
    };
  },
  computed: {
    hasTriggeredBy() {
      return this.pipeline.triggered_by && this.pipeline.triggered_by.length > 0;
    },
    hasTriggered() {
      return this.pipeline.triggered && this.pipeline.triggered.length > 0
    },
    /**
     * Calculates the margin top of the clicked downstream pipeline by
     * adding the height of each linked pipeline and the margin
     */
    marginTop() {
      return `${this.triggeredTopIndex * 52}px`;
    },
  },
  methods: {
    refreshTriggeredPipelineGraph() {
      this.$emit('refreshTriggeredPipelineGraph');
    },
    refreshTriggeredByPipelineGraph() {
      this.$emit('refreshTriggeredByPipelineGraph');
    },
    handleClickedDownstream(clickedPipeline, clickedIndex) {
      this.triggeredTopIndex = clickedIndex;
      this.$emit('onClickPipeline', 'triggered', this.pipeline.id, clickedPipeline);
    },
  },
};
