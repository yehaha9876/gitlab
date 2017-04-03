import CEMergeRequestStore from '../../stores/mr_widget_store';

export default class MergeRequestStore extends CEMergeRequestStore {
  constructor(data) {
    super(data);
    this.eeSetData(data);
  }

  eeSetData(data) {
    this.approvalsPath = data.approvals_path || this.approvalsPath;
    this.approvalsRequired = true;
  }

  setApprovals(data) {
    this.approvals = data;
  }
}
