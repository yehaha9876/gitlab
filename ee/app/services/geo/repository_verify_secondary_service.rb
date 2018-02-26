# rubocop:disable GitlabSecurity/PublicSend

module Geo
  class RepositoryVerifySecondaryService
    include Gitlab::Geo::LogHelpers

    def initialize(registry, type)
      @registry, @type   = registry, type.to_sym
      @original_checksum = @registry.send("project_#{type}_verification_checksum")
      @repo_path         = File.join(@registry.project.repository_storage_path, "#{@registry.repository_path(@type)}.git")
    end

    def execute
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?

      if repository_exists?(@type)
        compare_checksum
      else
        log_info("#{@type.to_s.capitalize} was not found at #{@repo_path}")
        record_status(error: "#{@type.to_s.capitalize} was not found: #{@repo_path}")
      end
    end

    # when should we verify?
    # - primary repository checksum has been calculated
    # - secondary repository checksum does not equal the primary repository checksum
    # - primary repository has not changed/is stable for some amount of time
    # - primary repository was checked after the last repository update
    # - secondary repository was successfully synced after the last repository update
    def self.should_verify_repository?(registry, type, stable_time = 6.hours.ago)
      original_checksum       = registry.send("project_#{type}_verification_checksum")
      secondary_checksum      = registry.send("#{type}_verification_checksum")
      last_verification_at    = registry.send("project_#{type}_last_verification")
      last_successful_sync_at = registry.send("last_#{type}_successful_sync_at")

      !original_checksum.nil? &&
        secondary_checksum != original_checksum &&
        registry.project.last_repository_updated_at < stable_time &&
        !last_verification_at.nil? && last_verification_at > registry.project.last_repository_updated_at &&
        !last_successful_sync_at.nil? && last_successful_sync_at > registry.project.last_repository_updated_at
    end

    private

    def compare_checksum
      checksum = calculate_checksum(@registry.project.repository_storage, @registry.repository_path(@type))

      if checksum != @original_checksum
        record_status(error: "#{@type.to_s.capitalize} checksum did not match: #{@repo_path}")
      else
        record_status(checksum: checksum)
      end
    rescue StandardError, Timeout::Error => e
      log_error("#{self.class.name} - #{e.message}")
      record_status(error: e.message)
    end

    def calculate_checksum(storage, relative_path)
      Gitlab::Git::RepositoryChecksum.new(storage, relative_path).calculate
    end

    def record_status(checksum: nil, error: nil)
      attrs = { "#{@type}_verification_checksum" => nil,
                "last_#{@type}_verification_at" => DateTime.now,
                "last_#{@type}_verification_failure" => nil,
                "last_#{@type}_verification_failed" => false }

      if checksum
        attrs["#{@type}_verification_checksum"] = checksum
      else
        attrs["last_#{@type}_verification_failed"]  = true
        attrs["last_#{@type}_verification_failure"] = error
        Gitlab::RepositoryCheckLogger.error(error)
      end

      @registry.update!(attrs)
    end

    def repository_exists?(type)
      case type
      when :repository
        @registry.project.repository_exists?
      when :wiki
        @registry.project.wiki_repository_exists?
      else
        false
      end
    end
  end
end
