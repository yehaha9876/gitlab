import Vue from 'vue';
import Assignee from '~/sidebar/components/assignees/assignees';
import UsersMock from './mock_data';

describe('Assignee component', () => {
  let component;
  let AssigneeComponent;

  beforeEach(() => {
    AssigneeComponent = Vue.extend(Assignee);
  });

  describe('No assignees/users', () => {
    it('displays only "No assignee" when no users are assigned and the issue is read-only', () => {
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users: [],
          editable: false,
        },
      }).$mount();
      const componentTextNoUsers = component.$el.querySelector('.assign-yourself').innerText.trim();

      expect(componentTextNoUsers).toBe('No assignee');
      expect(componentTextNoUsers.indexOf('assign yourself')).toEqual(-1);
    });

    it('displays only "No assignee" when no users are assigned and the issue can be edited', () => {
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users: [],
          editable: true,
        },
      }).$mount();
      const componentTextNoUsers = component.$el.querySelector('.assign-yourself').innerText.trim();

      expect(componentTextNoUsers.indexOf('No assignee')).toEqual(0);
      expect(componentTextNoUsers.indexOf('assign yourself')).toBeGreaterThan(0);
    });

    it('emits the assign-self event when "assign yourself" is clicked', () => {
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users: [],
          editable: true,
        },
      }).$mount();

      spyOn(component, '$emit');
      component.$el.querySelector('.assign-yourself .btn-link').click();
      expect(component.$emit).toHaveBeenCalledWith('assign-self');
    });
  });

  describe('One assignee/user', () => {
    it('Shows one user with avatar, username and author name', () => {
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users: [
            UsersMock.user,
          ],
          editable: true,
        },
      }).$mount();

      expect(component.$el.querySelector('.author_link')).not.toBeNull();
      // The image
      expect(component.$el.querySelector('.author_link img').getAttribute('src')).toEqual(UsersMock.user.avatarUrl);
      // Author name
      expect(component.$el.querySelector('.author_link .author').innerText.trim()).toEqual(UsersMock.user.name);
      // Username
      expect(component.$el.querySelector('.author_link .username').innerText.trim()).toEqual(`@${UsersMock.user.username}`);
    });
  });

  describe('Two or more assignees/users', () => {
    it('Shows two assignees', () => {
      const users = UsersMock.createNumberRandomUsers(2);
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users,
          editable: true,
        },
      }).$mount();

      expect(component.$el.querySelectorAll('.user-item').length).toEqual(users.length);
      expect(component.$el.querySelector('.user-list-more')).toBe(null);
    });

    it('Shows the hidden assignees label', () => {
      const users = UsersMock.createNumberRandomUsers(6);
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users,
          editable: true,
        },
      }).$mount();

      expect(component.$el.querySelectorAll('.user-item').length).toEqual(component.defaultRenderCount);
      expect(component.$el.querySelector('.user-list-more')).not.toBe(null);
      const usersLabelExpectation = users.length - component.defaultRenderCount;
      expect(component.$el.querySelector('.user-list-more .btn-link').innerText.trim())
        .not.toBe(`+${usersLabelExpectation} more`);
      component.toggleShowLess();
      Vue.nextTick(() => {
        expect(component.$el.querySelector('.user-list-more .btn-link').innerText.trim())
          .toBe('- show less');
      });
    });
  });
});
