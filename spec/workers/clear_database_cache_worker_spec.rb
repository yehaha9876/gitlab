require "spec_helper"

describe ClearDatabaseCacheWorker do
  let(:worker) { described_class.new }

  describe "#perform" do
    let!(:project) { create(:empty_project, description_html: "This is the cached text") }
    let!(:issue) { create(:issue, project: project, description_html: "Cached issue description") }
    let!(:other_issue) { create(:issue, description_html: "Cached issue description") }

    it "clears all caches when no scope was given" do
      worker.perform

      expect(project.reload.description_html).to be_nil
      expect(issue.reload.description_html).to be_nil
      expect(other_issue.reload.description_html).to be_nil
    end

    it "only clears the passed scopes when they are passed" do
      worker.perform("Issue" => { project_id: project.id })

      expect(project.reload.description_html).not_to be_nil
      expect(other_issue.reload.description_html).not_to be_nil

      expect(issue.reload.description_html).to be_nil
    end
  end

  describe "#caching_classes" do
    it "cleans up all classes when no scope was given" do
      expect(worker.caching_classes).to eq(CacheMarkdownField.caching_classes)
    end

    it "cleans up only given classes when scopes were given" do
      worker.perform("Project" => {}, "Issue" => {})

      expect(worker.caching_classes).to contain_exactly(Issue, Project)
    end
  end
end
