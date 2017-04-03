import Vue from 'vue';

import CEWidgetService from '../../services/mr_widget_service';

export default class MRWidgetService extends CEWidgetService {
  constructor(mr) {
    super(mr);
    this.approvalsResource = Vue.resource(mr.approvalsPath);
  }

  fetchApprovals() {
    return this.approvalsResource.get();
  }

  approveMergeRequest() {
    return this.approvalsResource.save();
  }

  unapproveMergeRequest() {
    return this.approvalsResource.delete();
  }
}
