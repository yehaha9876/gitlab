import CEMergeRequestStore from '../../stores/mr_widget_store';

export default class MergeRequestStore extends CEMergeRequestStore {
  constructor(data) {
    super(data);
    this.eeSetData(data);
  }

  eeSetData(data) {
    this.is_geo_secondary_node = true;
    this.approvalsPath = data.approvals_path || this.approvalsPath;
    this.approvalsRequired = true;
    this.approvals = null;
  }

  setApprovals(data) {
    this.approvals = data;
  }
}
