export default class ListMilestone {
  constructor(obj) {
    this.id = obj.id;
    this.title = obj.title;
    this.milestone = obj.milestone;
    this.path = obj.path;
    this.state = obj.state;
    this.webUrl = obj.web_url || obj.webUrl;
  }
}

window.ListMilestone = ListMilestone;
