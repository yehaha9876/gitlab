import Vue from 'vue';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import SidebarService from '~/sidebar/services/sidebar_service';
import Mock from './mock_data';

describe('Sidebar mediator', () => {
  beforeEach(() => {
    Vue.http.interceptors.push(Mock.sidebarMockInterceptor);
    this.mediator = new SidebarMediator(Mock.mediator);
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
    Vue.http.interceptors = _.without(Vue.http.interceptors, Mock.sidebarMockInterceptor);
  });

  it('assigns yourself ', () => {
    this.mediator.assignYourself();

    expect(this.mediator.store.currentUser).toEqual(Mock.mediator.currentUser);
    expect(this.mediator.store.assignees[0]).toEqual(Mock.mediator.currentUser);
  });

  it('saves assignees', (done) => {
    this.mediator.saveAssignees('issue[assignee_ids]')
      .then((resp) => {
        expect(resp.status).toEqual(200);
        done();
      })
      .catch(done.fail);
  });

  it('fetches the data', () => {
    spyOn(this.mediator.service, 'get').and.callThrough();
    this.mediator.fetch();
    expect(this.mediator.service.get).toHaveBeenCalled();
  });

  it('sets moveToProjectId', () => {
    const projectId = 7;
    spyOn(this.mediator.store, 'setMoveToProjectId').and.callThrough();

    this.mediator.setMoveToProjectId(projectId);

    expect(this.mediator.store.setMoveToProjectId).toHaveBeenCalledWith(projectId);
  });

  it('fetches autocomplete projects', (done) => {
    const searchTerm = 'foo';
    spyOn(this.mediator.service, 'getProjectsAutocomplete').and.callThrough();
    spyOn(this.mediator.store, 'setAutocompleteProjects').and.callThrough();

    this.mediator.fetchAutocompleteProjects(searchTerm)
      .then(() => {
        expect(this.mediator.service.getProjectsAutocomplete).toHaveBeenCalledWith(searchTerm);
        expect(this.mediator.store.setAutocompleteProjects).toHaveBeenCalled();
        done();
      })
      .catch(done.fail);
  });

  it('moves issue', (done) => {
    const moveToProjectId = 7;
    this.mediator.store.setMoveToProjectId(moveToProjectId);
    spyOn(this.mediator.service, 'moveIssue').and.callThrough();
    spyOn(gl.utils, 'visitUrl');

    this.mediator.moveIssue()
      .then(() => {
        expect(this.mediator.service.moveIssue).toHaveBeenCalledWith(moveToProjectId);
        expect(gl.utils.visitUrl).toHaveBeenCalledWith('/root/some-project/issues/5');
        done();
      })
      .catch(done.fail);
  });
});
