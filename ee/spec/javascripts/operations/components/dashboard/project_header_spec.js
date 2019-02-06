import { shallowMount, createLocalVue } from '@vue/test-utils';
import ProjectHeader from 'ee/operations/components/dashboard/project_header.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar/default.vue';
import { removeWhitespace } from 'spec/helpers/vue_component_helper';
import { mockOneProject, mockText } from '../../mock_data';

const localVue = createLocalVue();

describe('project header component', () => {
  let wrapper;

  const factory = () => {
    wrapper = shallowMount(localVue.extend(ProjectHeader), {
      propsData: {
        project: mockOneProject,
      },
      localVue,
      sync: false,
    });
  };

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders project name with namespace', () => {
    const namespace = wrapper.$el.querySelector('.js-project-namespace').text();
    const name = wrapper.$el.querySelector('.js-project-name').text();

    expect(removeWhitespace(namespace).trim()).toBe(`${mockOneProject.namespace.name} /`);
    expect(removeWhitespace(name).trim()).toBe(mockOneProject.name);
  });

  it('links project name to project', () => {
    const path = mockOneProject.web_url;

    expect(wrapper.find('.js-project-link').attributes('href')).toBe(path);
  });

  describe('wrapped components', () => {
    describe('project avatar', () => {
      it('renders', () => {
        expect(wrapper.findAll(ProjectAvatar).length).toBe(1);
      });

      it('binds project', () => {
        expect(wrapper.find(ProjectAvatar).props('project')).toEqual(mockOneProject);
      });
    });
  });

  describe('dropdown menu', () => {
    it('renders removal button', () => {
      expect(
        wrapper
          .find('.js-remove-button')
          .text()
          .trim(),
      ).toBe(mockText.REMOVE_PROJECT);
    });

    it('emits project removal link on click', () => {
      wrapper.find('.js-remove-button').trigger('click');

      expect(wrapper.emittedByOrder()).toEqual([
        { name: 'remove', args: [mockOneProject.remove_path] },
      ]);
    });
  });
});
