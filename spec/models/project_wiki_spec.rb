require "spec_helper"

describe ProjectWiki do
  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:user) { project.owner }
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:project_wiki) { described_class.new(project, user) }

  subject { project_wiki }

  before do
    project_wiki.wiki
  end

  describe "#path_with_namespace" do
    it "returns the project path with namespace with the .wiki extension" do
      expect(subject.path_with_namespace).to eq(project.full_path + '.wiki')
    end

    it 'returns the same value as #full_path' do
      expect(subject.path_with_namespace).to eq(subject.full_path)
    end
  end

  describe '#web_url' do
    it 'returns the full web URL to the wiki' do
      expect(subject.web_url).to eq("#{Gitlab.config.gitlab.url}/#{project.full_path}/wikis/home")
    end
  end

  describe "#url_to_repo" do
    it "returns the correct ssh url to the repo" do
      expect(subject.url_to_repo).to eq(gitlab_shell.url_to_repo(subject.full_path))
    end
  end

  describe "#ssh_url_to_repo" do
    it "equals #url_to_repo" do
      expect(subject.ssh_url_to_repo).to eq(subject.url_to_repo)
    end
  end

  describe "#http_url_to_repo" do
    let(:project) { create :project }

    it 'returns the full http url to the repo' do
      expected_url = "#{Gitlab.config.gitlab.url}/#{subject.full_path}.git"

      expect(project_wiki.http_url_to_repo).to eq(expected_url)
      expect(project_wiki.http_url_to_repo).not_to include('@')
    end
  end

  describe "#kerberos_url_to_repo" do
    it 'returns valid kerberos url for this repo' do
      gitlab_kerberos_url = Gitlab.config.build_gitlab_kerberos_url
      repo_kerberos_url = "#{gitlab_kerberos_url}/#{subject.full_path}.git"
      expect(subject.kerberos_url_to_repo).to eq(repo_kerberos_url)
    end
  end

  describe "#wiki_base_path" do
    it "returns the wiki base path" do
      wiki_base_path = "#{Gitlab.config.gitlab.relative_url_root}/#{project.full_path}/wikis"

      expect(subject.wiki_base_path).to eq(wiki_base_path)
    end
  end

  describe "#wiki" do
    it "contains a Gollum::Wiki instance" do
      expect(subject.wiki).to be_a Gollum::Wiki
    end

    it "creates a new wiki repo if one does not yet exist" do
      expect(project_wiki.create_page("index", "test content")).to be_truthy
    end

    it "raises CouldNotCreateWikiError if it can't create the wiki repository" do
      allow(project_wiki).to receive(:init_repo).and_return(false)
      expect { project_wiki.send(:create_repo!) }.to raise_exception(ProjectWiki::CouldNotCreateWikiError)
    end
  end

  describe "#empty?" do
    context "when the wiki repository is empty" do
      before do
        allow_any_instance_of(Gitlab::Shell).to receive(:add_repository) do
          create_temp_repo("#{Rails.root}/tmp/test-git-base-path/non-existant.wiki.git")
        end
        allow(project).to receive(:full_path).and_return("non-existant")
      end

      describe '#empty?' do
        subject { super().empty? }
        it { is_expected.to be_truthy }
      end
    end

    context "when the wiki has pages" do
      before do
        project_wiki.create_page("index", "This is an awesome new Gollum Wiki")
      end

      describe '#empty?' do
        subject { super().empty? }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe "#pages" do
    before do
      create_page("index", "This is an awesome new Gollum Wiki")
      @pages = subject.pages
    end

    after do
      destroy_page(@pages.first.page)
    end

    it "returns an array of WikiPage instances" do
      expect(@pages.first).to be_a WikiPage
    end

    it "returns the correct number of pages" do
      expect(@pages.count).to eq(1)
    end
  end

  describe "#find_page" do
    before do
      create_page("index page", "This is an awesome Gollum Wiki")
    end

    after do
      destroy_page(subject.pages.first.page)
    end

    it "returns the latest version of the page if it exists" do
      page = subject.find_page("index page")
      expect(page.title).to eq("index page")
    end

    it "returns nil if the page does not exist" do
      expect(subject.find_page("non-existant")).to eq(nil)
    end

    it "can find a page by slug" do
      page = subject.find_page("index-page")
      expect(page.title).to eq("index page")
    end

    it "returns a WikiPage instance" do
      page = subject.find_page("index page")
      expect(page).to be_a WikiPage
    end
  end

  describe '#find_file' do
    before do
      file = Gollum::File.new(subject.wiki)
      allow_any_instance_of(Gollum::Wiki)
                   .to receive(:file).with('image.jpg', 'master', true)
                   .and_return(file)
      allow_any_instance_of(Gollum::File)
                   .to receive(:mime_type)
                   .and_return('image/jpeg')
      allow_any_instance_of(Gollum::Wiki)
                   .to receive(:file).with('non-existant', 'master', true)
                   .and_return(nil)
    end

    after do
      allow_any_instance_of(Gollum::Wiki).to receive(:file).and_call_original
      allow_any_instance_of(Gollum::File).to receive(:mime_type).and_call_original
    end

    it 'returns the latest version of the file if it exists' do
      file = subject.find_file('image.jpg')
      expect(file.mime_type).to eq('image/jpeg')
    end

    it 'returns nil if the page does not exist' do
      expect(subject.find_file('non-existant')).to eq(nil)
    end

    it 'returns a Gollum::File instance' do
      file = subject.find_file('image.jpg')
      expect(file).to be_a Gollum::File
    end
  end

  describe "#create_page" do
    after do
      destroy_page(subject.pages.first.page)
    end

    it "creates a new wiki page" do
      expect(subject.create_page("test page", "this is content")).not_to eq(false)
      expect(subject.pages.count).to eq(1)
    end

    it "returns false when a duplicate page exists" do
      subject.create_page("test page", "content")
      expect(subject.create_page("test page", "content")).to eq(false)
    end

    it "stores an error message when a duplicate page exists" do
      2.times { subject.create_page("test page", "content") }
      expect(subject.error_message).to match(/Duplicate page:/)
    end

    it "sets the correct commit message" do
      subject.create_page("test page", "some content", :markdown, "commit message")
      expect(subject.pages.first.page.version.message).to eq("commit message")
    end

    it 'updates project activity' do
      subject.create_page('Test Page', 'This is content')

      project.reload

      expect(project.last_activity_at).to be_within(1.minute).of(Time.now)
      expect(project.last_repository_updated_at).to be_within(1.minute).of(Time.now)
    end
  end

  describe "#update_page" do
    before do
      create_page("update-page", "some content")
      @gollum_page = subject.wiki.paged("update-page")
      subject.update_page(
        @gollum_page,
        content: "some other content",
        format: :markdown,
        message: "updated page"
      )
      @page = subject.pages.first.page
    end

    after do
      destroy_page(@page)
    end

    it "updates the content of the page" do
      expect(@page.raw_data).to eq("some other content")
    end

    it "sets the correct commit message" do
      expect(@page.version.message).to eq("updated page")
    end

    it 'updates project activity' do
      subject.update_page(
        @gollum_page,
        content: 'Yet more content',
        format: :markdown,
        message: 'Updated page again'
      )

      project.reload

      expect(project.last_activity_at).to be_within(1.minute).of(Time.now)
      expect(project.last_repository_updated_at).to be_within(1.minute).of(Time.now)
    end
  end

  describe "#delete_page" do
    before do
      create_page("index", "some content")
      @page = subject.wiki.paged("index")
    end

    it "deletes the page" do
      subject.delete_page(@page)
      expect(subject.pages.count).to eq(0)
    end

    it 'updates project activity' do
      subject.delete_page(@page)

      project.reload

      expect(project.last_activity_at).to be_within(1.minute).of(Time.now)
      expect(project.last_repository_updated_at).to be_within(1.minute).of(Time.now)
    end
  end

  describe '#create_repo!' do
    it 'creates a repository' do
      expect(subject).to receive(:init_repo)
        .with(subject.full_path)
        .and_return(true)

      expect(subject.repository).to receive(:after_create)

      expect(subject.create_repo!).to be_an_instance_of(Gollum::Wiki)
    end
  end

  describe '#ensure_repository' do
    it 'creates the repository if it not exist' do
      allow(subject).to receive(:repository_exists?).and_return(false)

      expect(subject).to receive(:create_repo!)

      subject.ensure_repository
    end

    it 'does not create the repository if it exists' do
      allow(subject).to receive(:repository_exists?).and_return(true)

      expect(subject).not_to receive(:create_repo!)

      subject.ensure_repository
    end
  end

  describe '#hook_attrs' do
    it 'returns a hash with values' do
      expect(subject.hook_attrs).to be_a Hash
      expect(subject.hook_attrs.keys).to contain_exactly(:web_url, :git_ssh_url, :git_http_url, :path_with_namespace, :default_branch)
    end
  end

  private

  def create_temp_repo(path)
    FileUtils.mkdir_p path
    system(*%W(#{Gitlab.config.git.bin_path} init --quiet --bare -- #{path}))
  end

  def remove_temp_repo(path)
    FileUtils.rm_rf path
  end

  def commit_details
    { name: user.name, email: user.email, message: "test commit" }
  end

  def create_page(name, content)
    subject.wiki.write_page(name, :markdown, content, commit_details)
  end

  def destroy_page(page)
    subject.wiki.delete_page(page, commit_details)
  end
end
