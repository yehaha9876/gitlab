import state from '~/environments/stores/state';

describe('environments store state', () => {
  describe('initial state for environments app', () => {
    let initialState;

    beforeEach(() => {
      loadFixtures('projects/environments/app.html.raw');
      initialState = state(document.getElementById('environments-list-view').dataset);
    });

    it('sets canCreateDeployment', () => {
      expect(initialState.canCreateDeployment).toBe(true);
    });

    it('sets canCreateEnvironment', () => {
      expect(initialState.canCreateEnvironment).toBe(true);
    });

    it('sets canReadEnvironment', () => {
      expect(initialState.canReadEnvironment).toBe(true);
    });

    it('sets cssContainerClass', () => {
      expect(initialState.cssContainerClass).toBe('container-fluid container-limited');
    });

    it('sets endpoint', () => {
      expect(initialState.endpoint).toBe(
        'http://test.host/frontend-fixtures/builds-project/environments.json',
      );
    });

    it('sets folderName', () => {
      expect(initialState.folderName).not.toBeDefined();
    });

    it('sets helpPagePath', () => {
      expect(initialState.helpPagePath).toBe('http://test.host/help/ci/environments');
    });
  });

  describe('initial state for environments folder view', () => {
    let initialState;

    beforeEach(() => {
      loadFixtures('projects/environments/folder.html.raw');
      initialState = state(document.getElementById('environments-folder-list-view').dataset);
    });

    it('sets canCreateDeployment', () => {
      expect(initialState.canCreateDeployment).toBe(true);
    });

    it('sets canCreateEnvironment', () => {
      expect(initialState.canCreateEnvironment).toBe(false);
    });

    it('sets canReadEnvironment', () => {
      expect(initialState.canReadEnvironment).toBe(true);
    });

    it('sets cssContainerClass', () => {
      expect(initialState.cssContainerClass).toBe('container-fluid container-limited');
    });

    it('sets endpoint', () => {
      expect(initialState.endpoint).toBe(
        'http://test.host/frontend-fixtures/builds-project/environments/folders/0.json',
      );
    });

    it('sets folderName', () => {
      expect(initialState.folderName).toBe('0');
    });

    it('sets helpPagePath', () => {
      expect(initialState.helpPagePath).not.toBeDefined();
    });
  });
});
