require 'rails_helper'

describe MirrorHelper do
  let(:project) { build(:project) }

  describe '#mirrors_form_data_attributes' do
    it 'has required properties for repository mirroring' do
      expect(helper.mirrors_form_data_attributes(project)).to include(project_id: project.id,
                                                                      project_mirror_endpoint: project_mirror_path(project, :json),
                                                                      project_mirror_ssh_endpoint: ssh_host_keys_project_mirror_path(project, :json))
    end
  end
end
