require 'spec_helper'

feature 'New project' do
  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  context 'repository mirrors' do
    context 'when licensed' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'shows mirror repository checkbox enabled', :js do
        visit new_project_path
        find('#import-project-tab').click
        first('.js-import-git-toggle-button').click

        expect(page).to have_unchecked_field('Mirror repository', disabled: false)
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does not show mirror repository option' do
        visit new_project_path
        first('.js-import-git-toggle-button').click

        expect(page).not_to have_content('Mirror repository')
      end
    end
  end

  context 'CI/CD-only projects', :js do
    let(:repo) do
      OpenStruct.new(
        id: 123,
        login: 'some-github-repo',
        owner: OpenStruct.new(login: 'some-github-repo'),
        name: 'some-github-repo',
        full_name: 'my-user/some-github-repo',
        clone_url: 'https://github.com/my-user/some-github-repo.git'
      )
    end

    context 'when licensed' do
      before do
        stub_licensed_features(ci_cd_projects: true)

        visit new_project_path
        find('#ci-cd-project-tab').click
      end

      it 'shows CI/CD tab and pane' do
        expect(page).to have_css('#ci-cd-project-pane')
      end

      it 'creates CI/CD-only project from repo URL' do
        page.within '#ci-cd-project-pane' do
          find('.js-import-git-toggle-button').click

          fill_in 'project_import_url', with: 'http://foo.git'
          fill_in 'project_path', with: 'ci-cd-project1'
          choose 'project_visibility_level_20'
          click_button 'Create project'

          expect(current_path).to eq(project_path(Project.last))
          expect(Project.last.ci_cd_only).to eq(true)
        end
      end

      it 'creates CI/CD-only project from GitHub' do
        page.within '#ci-cd-project-pane' do
          find('.js-import-github').click
        end

        expect(page).to have_text('Connect repositories from GitHub')

        allow_any_instance_of(Gitlab::LegacyGithubImport::Client).to receive(:repos).and_return([repo])

        fill_in 'personal_access_token', with: 'fake-token'
        click_button 'List your GitHub repositories'
        wait_for_requests

        # Mock the POST `/import/github`
        allow_any_instance_of(Gitlab::LegacyGithubImport::Client).to receive(:repo).and_return(repo)
        project = create(:project, name: 'some-github-repo', creator: user, ci_cd_only: true, import_type: 'github', import_status: 'finished')
        allow_any_instance_of(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:execute).with(hash_including(ci_cd_only: true))
          .and_return(project)

        click_button 'Connect'
        wait_for_requests

        expect(page).to have_text('Started')
        wait_for_requests

        expect(page).to have_text('Done')

        expect(Project.last.name).to eq('some-github-repo')
        expect(Project.last.ci_cd_only).to eq(true)
      end

      it 'stays on GitHub import page after access token failure' do
        visit new_project_path
        find('#ci-cd-project-tab').click

        page.within '#ci-cd-project-pane' do
          find('.js-import-github').click
        end

        allow_any_instance_of(Gitlab::LegacyGithubImport::Client).to receive(:repos).and_raise(Octokit::Unauthorized)

        fill_in 'personal_access_token', with: 'unauthorized-fake-token'
        click_button 'List your GitHub repositories'

        expect(page).to have_text('Access denied to your GitHub account.')
        expect(page).to have_current_path(new_import_github_path(ci_cd_only: true))
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(ci_cd_projects: false)
      end

      it 'does not show CI/CD only tab' do
        visit new_project_path

        expect(page).not_to have_css('#ci-cd-project-tab')
      end
    end
  end
end
