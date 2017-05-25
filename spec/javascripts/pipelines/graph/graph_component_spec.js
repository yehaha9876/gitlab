import Vue from 'vue';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';
import graphJSON from './mock_data';

const GraphComponent = Vue.extend(graphComponent);

fdescribe('graph component', () => {
  preloadFixtures('static/graph.html.raw');

  beforeEach(() => {
    loadFixtures('static/graph.html.raw');
  });

  describe('while is loading', () => {
    it('should render a loading icon', () => {
      const component = new GraphComponent().$mount('#js-pipeline-graph-vue');
      expect(component.$el.querySelector('.loading-icon')).toBeDefined();
    });
  });

  describe('with a successful response', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify(graphJSON), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    describe('rendered output', () => {
      const component = new GraphComponent().$mount('#js-pipeline-graph-vue');

      it('should include the pipelines graph', () => {
        expect(component.$el.classList.contains('js-pipeline-graph')).toEqual(true);
      });

      it('should include the first column with no margin', () => {
        const firstColumn = component.$el.querySelector('.stage-column:first-child');
        expect(firstColumn.classList.contains('no-margin')).toEqual(true);
      });

      it('should include the second column with a left margin', () => {
        const secondColumn = component.$el.querySelector('.stage-column:nth-child(2)');
        expect(secondColumn.classList.contains('left-margin')).toEqual(true);
      });

      it('should include the second column first build with a left connector', () => {
        const firstBuild = component.$el.querySelector('.stage-column:nth-child(2) .build:nth-child(1)');
        expect(firstBuild.classList.contains('left-connector')).toEqual(true);
      });

      it('should not include the loading icon', () => {
        expect(component.$el.querySelector('loading-icon')).toBe(null);
      });

      it('should include the stage column list', () => {
        expect(component.$el.querySelector('.stage-column-list')).toBeDefined();
      });
    });

    describe('methods', () => {
      const component = new GraphComponent().$mount('#js-pipeline-graph-vue');

      describe('stageConnectorClass', () => {
        it('returns no-margin when it is the first stage column and only has one job', () => {
          // TODO: Stretch -- unrelated, but should be added
        });

        it('returns whatttt when it is the first stage column but multiple jobs', () => {
          // TODO: Stretch -- unrelated, but should be added
        });

        it('returns left-margin when it is not the first column', () => {
          // TODO: Stretch -- unrelated, but should be added
        });
      });

      describe('capitalizeStageName', () => {
        it('returns a capitalized stage name', () => {
          // TODO: Stretch -- unrelated, but should be added
        });
      });
    });

    describe('setup', () => {
      const component = new GraphComponent().$mount('#js-pipeline-graph-vue');

      it('polling is started when the component is created', () => {
        // TODO: Stretch -- unrelated, but should be added
      });

      it('polling is stopped when visibility is hidden', () => {
        // TODO: Stretch -- unrelated, but should be added
      });

      it('polling is restarted when visibility is shown', () => {
        // TODO: Stretch -- unrelated, but should be added
      });
    });
  });

  describe('Linked Pipelines', () => {
    describe('when upstream pipelines are defined', () => {
      const component = new GraphComponent().$mount('#js-pipeline-graph-vue');

      it('should render an upstream pipelines column', () => {
        expect(component.$el.querySelector('.linked-pipelines-column')).not.toBeNull();
        expect(component.$el.querySelector('.linked-pipelines-column-title').innerText).toContain('Upstream');
      });

      it('should render the upstream column with no margin', () => {
        // TODO:
      });

      it('should render the first stage column with left-margin', () => {
        // TODO:
      });
    });

    describe('when downstream pipelines are defined', () => {
      const component = new GraphComponent().$mount('#js-pipeline-graph-vue');

      it('should render a downstream pipelines column', () => {
        expect(component.$el.querySelector('.linked-pipelines-column')).not.toBeNull();
        expect(component.$el.querySelector('.linked-pipelines-column-title').innerText).toContain('Downstream');
      });
    });

    describe('when neither upstream nor downstream pipelines are defined', () => {
      const component = new GraphComponent().$mount('#js-pipeline-graph-vue');

      it('should not render a linked pipelines column', () => {
        expect(component.$el.querySelector('.linked-pipelines-column')).toBeNull();
      });
    });
  });
});
