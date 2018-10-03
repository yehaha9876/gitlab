import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/modal.vue';
import state from 'ee/vue_shared/security_reports/store/state';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Security Reports modal', () => {
  const Component = Vue.extend(component);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with permissions', () => {
    describe('with dismissed issue', () => {
      beforeEach(() => {
        const props = {
          modal: state().modal,
          canCreateFeedbackPermission: true,
        };
        props.modal.vulnerability.isDismissed = true;
        props.modal.vulnerability.dismissalFeedback = {
          author: { username: 'jsmith' },
          pipeline: { id: '123' },
        };
        vm = mountComponent(Component, props);
      });

      it('renders dismissal author and associated pipeline', () => {
        expect(vm.$el.textContent.trim()).toContain('@jsmith');
        expect(vm.$el.textContent.trim()).toContain('#123');
      });

      it('renders button to revert dismissal', () => {
        expect(vm.$el.querySelector('.js-dismiss-btn').textContent.trim()).toEqual(
          'Revert dismissal',
        );
      });

      it('calls revertDismissed when revert dismissal button is clicked', () => {
        spyOn(vm, 'revertDismissIssue');

        const button = vm.$el.querySelector('.js-dismiss-btn');
        button.click();

        expect(vm.revertDismissIssue).toHaveBeenCalled();
      });
    });

    describe('with not dismissed issue', () => {
      beforeEach(() => {
        const props = {
          modal: state().modal,
          canCreateFeedbackPermission: true,
        };
        vm = mountComponent(Component, props);
      });

      it('renders button to dismiss issue', () => {
        expect(vm.$el.querySelector('.js-dismiss-btn').textContent.trim()).toEqual(
          'Dismiss vulnerability',
        );
      });

      it('calls dismissIssue when dismiss issue button is clicked', () => {
        spyOn(vm, 'dismissIssue');

        const button = vm.$el.querySelector('.js-dismiss-btn');
        button.click();

        expect(vm.dismissIssue).toHaveBeenCalled();
      });
    });

    describe('with instances', () => {
      beforeEach(() => {
        const props = {
          modal: state().modal,
        };
        props.modal.data.instances.value = [
          { uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc' },
          { uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md' },
        ];
        vm = mountComponent(Component, props);
      });

      it('renders instances list', () => {
        const instances = vm.$el.querySelectorAll('.report-block-list li');

        expect(instances[0].textContent).toContain(
          'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
        );
        expect(instances[1].textContent).toContain(
          'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
        );
      });
    });

    describe('data & create issue button', () => {
      beforeEach(() => {
        const props = {
          modal: state().modal,
          vulnerabilityFeedbackHelpPath: 'feedbacksHelpPath',
        };
        props.modal.title = 'Arbitrary file existence disclosure in Action Pack';
        props.modal.data.solution.value = 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8';
        props.modal.data.file.value = 'Gemfile.lock';
        props.modal.data.file.url = 'path/Gemfile.lock';
        vm = mountComponent(Component, props);
      });

      it('renders keys in `data`', () => {
        expect(vm.$el.textContent).toContain('Arbitrary file existence disclosure in Action Pack');
        expect(vm.$el.textContent).toContain(
          'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
        );
      });

      it('renders link fields with link', () => {
        expect(vm.$el.querySelector('.js-link-file').getAttribute('href')).toEqual('path/Gemfile.lock');
      });

      it('renders help link', () => {
        expect(vm.$el.querySelector('.js-link-vulnerabilityFeedbackHelpPath').getAttribute('href')).toEqual('feedbacksHelpPath');
      });
    });
  });

  describe('without permissions', () => {
    beforeEach(() => {
      const props = {
        modal: state().modal,
      };
      vm = mountComponent(Component, props);
    });

    it('does not render action buttons', () => {
      expect(vm.$el.querySelector('.js-dismiss-btn')).toBe(null);
      expect(vm.$el.querySelector('.js-create-issue-btn')).toBe(null);
    });

    it('does not display the footer', () => {
      expect(vm.$el.classList.contains('modal-hide-footer')).toEqual(true);
    });
  });

  describe('with permission to create issue', () => {
    beforeEach(() => {
      const props = {
        modal: state().modal,
        canCreateIssuePermission: true,
      };
      vm = mountComponent(Component, props);
    });

    it('does not render dismiss button', () => {
      expect(vm.$el.querySelector('.js-dismiss-btn')).toBe(null);
    });

    it('renders create issue button', () => {
      expect(vm.$el.querySelector('.js-create-issue-btn')).not.toBe(null);
    });

    it('renders the footer', () => {
      expect(vm.$el.classList.contains('modal-hide-footer')).toEqual(false);
    });
  });

  describe('with permission to dismiss issue', () => {
    beforeEach(() => {
      const props = {
        modal: state().modal,
        canCreateFeedbackPermission: true,
      };
      vm = mountComponent(Component, props);
    });

    it('does not render create issue button', () => {
      expect(vm.$el.querySelector('.js-create-issue-btn')).toBe(null);
    });

    it('renders create issue button and footer', () => {
      expect(vm.$el.querySelector('.js-dismiss-btn')).not.toBe(null);
    });

    it('renders the footer', () => {
      expect(vm.$el.classList.contains('modal-hide-footer')).toEqual(false);
    });
  });

  describe('with a resolved issue', () => {
    beforeEach(() => {
      const props = {
        modal: state().modal,
      };
      props.modal.isResolved = true;
      vm = mountComponent(Component, props);
    });

    it('does not display the footer', () => {
      expect(vm.$el.classList.contains('modal-hide-footer')).toBeTruthy();
    });
  });
});
