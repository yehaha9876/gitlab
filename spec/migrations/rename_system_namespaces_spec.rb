require "spec_helper"
require Rails.root.join("db", "post_migrate", "20170316163800_rename_system_namespaces.rb")

describe RenameSystemNamespaces, truncate: true do
  let(:migration) { described_class.new }
  let(:test_dir) { File.join(Rails.root, "tmp", "tests", "rename_namespaces_test") }
  let(:uploads_dir) { File.join(test_dir, "public", "uploads") }
  let(:system_namespace) do
    namespace = build(:namespace, path: "system")
    namespace.save(validate: false)
    namespace
  end

  before do
    FileUtils.remove_dir(test_dir) if File.directory?(test_dir)
    FileUtils.mkdir_p(uploads_dir)
    FileUtils.remove_dir(TestEnv.repos_path) if File.directory?(TestEnv.repos_path)
    allow(migration).to receive(:say)
    allow(migration).to receive(:uploads_dir).and_return(uploads_dir)
  end

  describe "#system_namespaces" do
    before do
      system_namespace
    end

    it "includes namespaces called with path `system`" do
      expect(migration.system_namespaces.map(&:id)).to include(system_namespace.id)
    end
  end

  describe "#up" do
    before do
      system_namespace
    end

    it "renames namespaces called system" do
      migration.up

      expect(system_namespace.reload.path).to eq("system0")
    end

    it "renames the route to the namespace" do
      migration.up

      expect(system_namespace.reload.full_path).to eq("system0")
    end

    it "renames the route for projects of the namespace" do
      project = create(:project, path: "project-path", namespace: system_namespace)

      migration.up

      expect(project.route.reload.path).to eq("system0/project-path")
    end

    it "moves the the repository for a project in the namespace" do
      create(:project, namespace: system_namespace, path: "system-project")
      expected_repo = File.join(TestEnv.repos_path, "system0", "system-project.git")

      migration.up

      expect(File.directory?(expected_repo)).to be(true)
    end

    it "moves the uploads for the namespace" do
      allow(migration).to receive(:move_namespace_folders).with(Settings.pages.path, "system", "system0")
      expect(migration).to receive(:move_namespace_folders).with(uploads_dir, "system", "system0")

      migration.up
    end

    it "moves the pages for the namespace" do
      allow(migration).to receive(:move_namespace_folders).with(uploads_dir, "system", "system0")
      expect(migration).to receive(:move_namespace_folders).with(Settings.pages.path, "system", "system0")

      migration.up
    end

    it "clears the markdown cache for projects in the system namespace" do
      project = create(:project, namespace: system_namespace)
      scopes = { "Project" => { id: [project.id] },
                 "Issue" => { project_id: [project.id] },
                 "MergeRequest" => { target_project_id: [project.id] },
                 "Note" => { project_id: [project.id] } }

      expect(ClearDatabaseCacheWorker).to receive(:perform_async).with(scopes)

      migration.up
    end

    context "system namespace -> subgroup -> system0 project" do
      it "updates the route of the project correctly" do
        subgroup = create(:group, path: "subgroup", parent: system_namespace)
        project = create(:project, path: "system0", namespace: subgroup)

        migration.up

        expect(project.route.reload.path).to eq("system0/subgroup/system0")
      end
    end

    context "for a sub-namespace" do
      before do
        system_namespace.parent = create(:namespace, path: "parent")
        system_namespace.save(validate: false)
      end

      it "renames the route to the namespace" do
        migration.up

        expect(system_namespace.reload.full_path).to eq("parent/system0")
      end

      it "moves the the repository for a project in the namespace" do
        create(:project, namespace: system_namespace, path: "system-project")
        expected_repo = File.join(TestEnv.repos_path, "parent", "system0", "system-project.git")

        migration.up

        expect(File.directory?(expected_repo)).to be(true)
      end

      it "moves the uploads for the namespace" do
        allow(migration).to receive(:move_namespace_folders).with(Settings.pages.path, "parent/system", "parent/system0")
        expect(migration).to receive(:move_namespace_folders).with(uploads_dir, "parent/system", "parent/system0")

        migration.up
      end

      it "moves the pages for the namespace" do
        allow(migration).to receive(:move_namespace_folders).with(uploads_dir, "parent/system", "parent/system0")
        expect(migration).to receive(:move_namespace_folders).with(Settings.pages.path, "parent/system", "parent/system0")

        migration.up
      end
    end
  end

  describe "#move_repositories" do
    let(:namespace) { create(:group, name: "hello-group") }
    it "moves a project for a namespace" do
      create(:project, namespace: namespace, path: "hello-project")
      expected_path = File.join(TestEnv.repos_path, "bye-group", "hello-project.git")

      migration.move_repositories(namespace, "hello-group", "bye-group")

      expect(File.directory?(expected_path)).to be(true)
    end

    it "moves a namespace in a subdirectory correctly" do
      child_namespace = create(:group, name: "sub-group", parent: namespace)
      create(:project, namespace: child_namespace, path: "hello-project")

      expected_path = File.join(TestEnv.repos_path, "hello-group", "renamed-sub-group", "hello-project.git")

      migration.move_repositories(child_namespace, "hello-group/sub-group", "hello-group/renamed-sub-group")

      expect(File.directory?(expected_path)).to be(true)
    end

    it "moves a parent namespace with subdirectories" do
      child_namespace = create(:group, name: "sub-group", parent: namespace)
      create(:project, namespace: child_namespace, path: "hello-project")
      expected_path = File.join(TestEnv.repos_path, "renamed-group", "sub-group", "hello-project.git")

      migration.move_repositories(child_namespace, "hello-group", "renamed-group")

      expect(File.directory?(expected_path)).to be(true)
    end
  end

  describe "#move_namespace_folders" do
    it "moves a namespace with files" do
      source = File.join(uploads_dir, "parent-group", "sub-group")
      FileUtils.mkdir_p(source)
      destination = File.join(uploads_dir, "parent-group", "moved-group")
      FileUtils.touch(File.join(source, "test.txt"))
      expected_file = File.join(destination, "test.txt")

      migration.move_namespace_folders(uploads_dir, File.join("parent-group", "sub-group"), File.join("parent-group", "moved-group"))

      expect(File.exist?(expected_file)).to be(true)
    end

    it "moves a parent namespace uploads" do
      source = File.join(uploads_dir, "parent-group", "sub-group")
      FileUtils.mkdir_p(source)
      destination = File.join(uploads_dir, "moved-parent", "sub-group")
      FileUtils.touch(File.join(source, "test.txt"))
      expected_file = File.join(destination, "test.txt")

      migration.move_namespace_folders(uploads_dir, "parent-group", "moved-parent")

      expect(File.exist?(expected_file)).to be(true)
    end
  end

  describe "#child_ids_for_parent" do
    it "collects child ids for all levels" do
      parent = create(:namespace)
      first_child = create(:namespace, parent: parent)
      second_child = create(:namespace, parent: parent)
      third_child = create(:namespace, parent: second_child)
      all_ids = [parent.id, first_child.id, second_child.id, third_child.id]

      collected_ids = migration.child_ids_for_parent(parent, ids: [parent.id])

      expect(collected_ids).to contain_exactly(*all_ids)
    end
  end

  describe "#remove_last_ocurrence" do
    it "removes only the last occurance of a string" do
      input = "this/is/system/namespace/with/system"

      expect(migration.remove_last_occurrence(input, "system")).to eq("this/is/system/namespace/with/")
    end
  end
end
