import CEMergeRequestStore from '../../stores/mr_widget_store';

export default class MergeRequestStore extends CEMergeRequestStore {
  setData(data) {
    super.setData(data);
    this.initGeo(data);
    this.initApprovals(data);
  }

  initGeo(data) {
    this.is_geo_secondary_node = data.is_geo_secondary_node;
  }

  initApprovals(data) {
    this.approvals = this.approvals || null;
    this.approvalsPath = data.approvals_path || this.approvalsPath;
    this.approvalsRequired = !!data.approvals_required;
    this.approvalsLeft = !!data.approvals_left;
  }

  setApprovals(data) {
    this.approvals = data;
    this.approvalsRequired = !!data.approvals_required;
    this.approvalsLeft = !!data.approvals_left;
    this.isFrozen = this.approvalsRequired && this.approvalsLeft;
  }
}
