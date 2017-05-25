const mockTriggerers = [
  { id: 111, path: 'hello/world/tho', project_name: 'My Project Name', details: { status: { icon: 'icon_status_pending', group: 'pending' } } },
];

const mockTriggereds = [
  { id: 111, path: 'hello/world/tho', project_name: 'My Project Name', details: { status: { icon: 'icon_status_pending', group: 'pending' } } },
  { id: 111, path: 'hello/world/tho', project_name: 'My Project Name', details: { status: { icon: 'icon_status_pending', group: 'pending' } } },
  { id: 111, path: 'hello/world/tho', project_name: 'My Project Name', details: { status: { icon: 'icon_status_pending', group: 'pending' } } },
];

export default class PipelineStore {
  constructor() {
    this.state = {};

    this.state.graph = [];
    this.state.triggered = [];
    this.state.triggerer = [];
  }

  storeGraph(graph = []) {
    this.state.graph = graph;
    this.state.triggered = mockTriggereds;
    this.state.triggerer = mockTriggerers;
  }
}
