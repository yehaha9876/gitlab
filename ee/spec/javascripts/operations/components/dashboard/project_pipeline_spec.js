import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import ProjectPipeline from 'ee/operations/components/dashboard/project_pipeline.vue';
import { mockProjectData, mockPipelineData } from '../../mock_data';

describe('project pipeline component', () => {
  let wrapper;
  let component;

  beforeEach(() => {
    wrapper = Vue.extend(ProjectPipeline);
  });

  afterEach(() => {
    component.$destroy();
  });

  describe('current pipeline only', () => {
    it('should render success badge', () => {
      component = mountComponent(wrapper, {
        status: mockProjectData(1, 'success')[0].last_pipeline.details.status,
        hasPipelineFailed: false,
      });

      expect(component.$el.querySelector('.js-ci-status-icon-success')).not.toBeNull();
    });

    it('should render failed badge', () => {
      component = mountComponent(wrapper, {
        status: mockProjectData(1, 'failed')[0].last_pipeline.details.status,
        hasPipelineFailed: true,
      });

      expect(component.$el.querySelector('.js-ci-status-icon-failed')).not.toBeNull();
    });

    it('should render running badge', () => {
      component = mountComponent(wrapper, {
        status: mockProjectData(1, 'running')[0].last_pipeline.details.status,
        hasPipelineFailed: false,
      });

      expect(component.$el.querySelector('.js-ci-status-icon-running')).not.toBeNull();
    });
  });

  describe('upstream pipeline', () => {
    it('should render upstream success badge', () => {
      const project = mockProjectData(1, 'success')[0];
      const upstreamPipeline = mockPipelineData('success');
      component = mountComponent(wrapper, {
        status: project.last_pipeline.details.status,
        upstreamPipeline,
        hasPipelineFailed: false,
      });

      expect(
        component.$el.querySelector('.js-upstream-pipeline-status.js-ci-status-icon-success'),
      ).not.toBeNull();
    });

    it('should render upstream failed badge', () => {
      const project = mockProjectData(1, 'success')[0];
      const upstreamPipeline = mockPipelineData('failed');
      component = mountComponent(wrapper, {
        status: project.last_pipeline.details.status,
        upstreamPipeline,
        hasPipelineFailed: false,
      });

      expect(
        component.$el.querySelector('.js-upstream-pipeline-status.js-ci-status-icon-failed'),
      ).not.toBeNull();
    });

    it('should render upstream running badge', () => {
      const project = mockProjectData(1, 'success')[0];
      const upstreamPipeline = mockPipelineData('running');
      component = mountComponent(wrapper, {
        status: project.last_pipeline.details.status,
        upstreamPipeline,
        hasPipelineFailed: false,
      });

      expect(
        component.$el.querySelector('.js-upstream-pipeline-status.js-ci-status-icon-running'),
      ).not.toBeNull();
    });
  });

  describe('downstream pipeline', () => {
    it('should render downstream success badge', () => {
      const project = mockProjectData(1, 'success')[0];
      const downstreamPipelines = [mockPipelineData('success')];
      component = mountComponent(wrapper, {
        status: project.last_pipeline.details.status,
        downstreamPipelines,
        hasPipelineFailed: false,
      });

      expect(
        component.$el.querySelector('.js-downstream-pipeline-status.js-ci-status-icon-success'),
      ).not.toBeNull();
    });

    it('should render downstream failed badge', () => {
      const project = mockProjectData(1, 'success')[0];
      const downstreamPipelines = [mockPipelineData('failed')];
      component = mountComponent(wrapper, {
        status: project.last_pipeline.details.status,
        downstreamPipelines,
        hasPipelineFailed: false,
      });

      expect(
        component.$el.querySelector('.js-downstream-pipeline-status.js-ci-status-icon-failed'),
      ).not.toBeNull();
    });

    it('should render downstream running badge', () => {
      const project = mockProjectData(1, 'success')[0];
      const downstreamPipelines = [mockPipelineData('running')];
      component = mountComponent(wrapper, {
        status: project.last_pipeline.details.status,
        downstreamPipelines,
        hasPipelineFailed: false,
      });

      expect(
        component.$el.querySelector('.js-downstream-pipeline-status.js-ci-status-icon-running'),
      ).not.toBeNull();
    });

    it('should render extra downstream icon', () => {
      const project = mockProjectData(1, 'success')[0];
      // 14 is the max we can show, so put 15 in the array
      const downstreamPipelines = Array.from(new Array(15), (val, index) =>
        mockPipelineData('running', index),
      );
      component = mountComponent(wrapper, {
        status: project.last_pipeline.details.status,
        downstreamPipelines,
        hasPipelineFailed: false,
      });

      expect(component.$el.querySelector('.js-downstream-extra-icon')).not.toBeNull();
    });
  });
});
