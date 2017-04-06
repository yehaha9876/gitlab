import CEMergeRequestStore from '../../stores/mr_widget_store';

export default class MergeRequestStore extends CEMergeRequestStore {
  setData(data) {
    super.setData(data);
    this.initGeo(data);
    this.initSquashBeforeMerge(data);
    this.initApprovals(data);
  }

  initSquashBeforeMerge(data) {
    this.squashBeforeMergeHelpPath = this.squashBeforeMergeHelpPath
      || data.squash_before_merge_help_path;
    this.enableSquashBeforeMerge = true;
  }

  initGeo(data) {
    this.isGeoSecondaryNode = this.isGeoSecondaryNode || data.is_geo_secondary_node;
    this.geoSecondaryHelpPath = this.geoSecondaryHelpPath || data.geo_secondary_help_path;
  }

  initApprovals(data) {
    this.approvals = this.approvals || null;
    this.approvalsPath = data.approvals_path || this.approvalsPath;
    this.approvalsRequired = !!data.approvals_required;
  }

  setApprovals(data) {
    this.approvals = data;
    this.approvalsLeft = !!data.approvals_left;
    this.isFrozen = this.approvalsRequired && this.approvalsLeft;
  }
}
