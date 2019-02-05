import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import Commit from '~/vue_shared/components/commit.vue';
import Project from 'ee/operations/components/dashboard/project.vue';
import ProjectHeader from 'ee/operations/components/dashboard/project_header.vue';
import Alerts from 'ee/operations/components/dashboard/alerts.vue';
import { getChildInstances } from '../../helpers';
import { mockOneProject } from '../../mock_data';

describe('project component', () => {
  const ProjectComponent = Vue.extend(Project);
  const ProjectHeaderComponent = Vue.extend(ProjectHeader);
  const AlertsComponent = Vue.extend(Alerts);
  const CommitComponent = Vue.extend(Commit);
  let vm;

  beforeEach(() => {
    vm = mountComponentWithStore(ProjectComponent, {
      props: {
        project: mockOneProject,
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('wrapped components', () => {
    describe('project header', () => {
      it('binds project', () => {
        const [header] = getChildInstances(vm, ProjectHeaderComponent);

        expect(header.project).toEqual(mockOneProject);
      });
    });

    describe('alerts', () => {
      let alert;

      beforeEach(() => {
        [alert] = getChildInstances(vm, AlertsComponent);
      });

      it('binds alert count to count', () => {
        expect(alert.count).toBe(mockOneProject.alert_count);
      });
    });

    describe('commit', () => {
      let commits;
      let commit;

      beforeEach(() => {
        commits = getChildInstances(vm, CommitComponent);
        [commit] = commits;
      });

      it('renders', () => {
        expect(commits.length).toBe(1);
      });

      it('binds commitRef', () => {
        expect(commit.commitRef).toBe(vm.commitRef);
      });

      it('binds short_id to shortSha', () => {
        expect(commit.shortSha).toBe(vm.project.last_pipeline.commit.short_id);
      });

      it('binds commitUrl', () => {
        expect(commit.commitUrl).toBe(vm.project.last_pipeline.commit.commit_url);
      });

      it('binds title', () => {
        expect(commit.title).toBe(vm.project.last_pipeline.commit.title);
      });

      it('binds author', () => {
        expect(commit.author).toBe(vm.project.last_pipeline.commit.author);
      });

      it('binds tag', () => {
        expect(commit.tag).toBe(vm.project.last_pipeline.ref.tag);
      });
    });

    describe('deploy finished at', () => {
      it('renders clock icon', () => {
        expect(vm.$el.querySelector('.ic-clock')).not.toBe(null);
      });

      it('renders time ago of finished time', () => {
        const timeago = '1 day ago';
        const container = vm.$el.querySelector('.js-dashboard-project-time-ago');

        expect(container.innerText.trim()).toBe(timeago);
      });
    });
  });
});
