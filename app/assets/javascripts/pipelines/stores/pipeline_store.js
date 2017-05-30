const mockTriggerers = [
  { id: 111, path: 'hello/world/tho', project_name: 'GitLab Shell', details: { status: { icon: 'icon_status_pending', group: 'pending' } } },
];

const mockTriggereds = [
  { id: 111, path: 'hello/world/tho', project_name: 'GitLab EE', details: { status: { icon: 'icon_status_failed', group: 'failed' } } },
  { id: 111, path: 'hello/world/tho', project_name: 'Gitaly', details: { status: { icon: 'icon_status_pending', group: 'pending' } } },
  { id: 111, path: 'hello/world/tho', project_name: 'GitHub', details: { status: { icon: 'icon_status_success', group: 'success' } } },
];

export default class PipelineStore {
  constructor() {
    this.state = {};

    this.state.graph = [];
    this.state.triggered = [];
    this.state.triggerer = [];
  }

  storeGraph(graph = []) {
    graph[3].groups.push(graph[3].groups[0]);
    this.state.graph = graph;
    this.state.triggered = mockTriggereds;
    this.state.triggerer = mockTriggerers;
  }
}
