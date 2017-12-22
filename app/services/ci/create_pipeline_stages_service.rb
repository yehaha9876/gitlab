module Ci
  class CreatePipelineStagesService < BaseService
    def execute(pipeline)
      pipeline.stage_seeds.each do |seed|
        seed.user = current_user

        seed.create! do |build|
          ##
          # Create the environment before the build starts. This sets its slug and
          # makes it available as an environment variable
          #
          if build.has_environment?
            environment_name = build.expanded_environment_name
            project.environments.find_or_create_by(name: environment_name)
          end

          # Touch empty trace and move it with CarrierWave
          build.create_job_artifacts_trace(
            project: build.project,
            file_type: :trace,
            file: File.open(FileUtils.touch(Ci::JobArtifact::TRACE_FILE_NAME).first))
        end
      end
    end
  end
end
