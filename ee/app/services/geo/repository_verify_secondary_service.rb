module Geo
  class RepositoryVerifySecondaryService
    include Gitlab::Geo::LogHelpers

    def initialize(registry, type)
      @registry, @type   = registry, type
      @original_checksum = @registry.send("project_#{type}_verification_checksum") # rubocop:disable GitlabSecurity/PublicSend
    end

    def execute
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?
      return unless self.class.should_verify_repository?(@registry, @type)

      log_info("Verifying #{@type.to_s.capitalize} at #{repository.path}")

      if repository.exists?
        checksum = calculate_checksum(repository)

        if checksum != @original_checksum
          record_status(nil, "#{@type.to_s.capitalize} checksum did not match")
        else
          record_status(checksum)
        end
      else
        log_info("#{@type.to_s.capitalize} was not found at #{repository.path}")
        record_status(nil, "#{@type.to_s.capitalize} was not found")
      end
    end

    # when should we verify?
    # - primary repository checksum has been calculated
    # - primary repository has not changed in 6 hours
    # - primary repository was checked after the last repository update
    # - secondary repository was successfully synced after the last repository update
    def self.should_verify_repository?(registry, type)
      checksum = registry.send("project_#{type}_verification_checksum") # rubocop:disable GitlabSecurity/PublicSend
      last_checked_at = registry.send("project_#{type}_last_check") # rubocop:disable GitlabSecurity/PublicSend
      last_successful_sync_at = registry.send("last_#{type}_successful_sync_at") # rubocop:disable GitlabSecurity/PublicSend

      checksum &&
        registry.project.last_repository_updated_at < 6.hours.ago &&
        !last_checked_at.nil? && last_checked_at > registry.project.last_repository_updated_at &&
        !last_successful_sync_at.nil? && last_successful_sync_at > registry.project.last_repository_updated_at
    end

    private

    def repository
      @repository ||= @registry.repository(@type)
    end

    def record_status(checksum: nil, error: nil)
      attrs = { "#{@type}_verification_checksum" => nil,
                "last_#{@type}_verification_at" => nil,
                "last_#{@type}_verification_failure" => nil }

      if checksum
        attrs["#{@type}_verification_checksum"] = checksum
        attrs["last_#{@type}_verification_at"] = Time.now
      else
        attrs["last_#{@type}_verification_failure"] = error
      end

      @registry.update!(attrs)
    end

    def calculate_checksum(repository)
      # repository.calculate_checksum TODO it will probably be this

      # TODO temporary for now
      repo = Rugged::Repository.new(repository.path)
      repo.references.inject(nil) do |checksum, ref|
        value = Digest::SHA1.hexdigest((ref.target&.oid || '') + ref.name)

        if checksum.nil?
          value
        else
          (checksum.hex ^ value.hex).to_s(16)
        end
      end
    end
  end
end
