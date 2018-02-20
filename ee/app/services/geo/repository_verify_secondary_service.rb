# rubocop:disable GitlabSecurity/PublicSend

module Geo
  class RepositoryVerifySecondaryService
    include Gitlab::Geo::LogHelpers

    def initialize(registry, type)
      @registry, @type   = registry, type
      @original_checksum = @registry.send("project_#{type}_verification_checksum")
    end

    def execute
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?
      return unless self.class.should_verify_repository?(@registry, @type)

      if repository_exits?(@type)
        compare_checksum
      else
        log_info("#{@type.to_s.capitalize} was not found at #{@registry.repository_path(@type)}")
        record_status(nil, "#{@type.to_s.capitalize} was not found")
      end
    end

    # when should we verify?
    # - primary repository checksum has been calculated
    # - primary repository has not changed in 6 hours
    # - primary repository was checked after the last repository update
    # - secondary repository was successfully synced after the last repository update
    def self.should_verify_repository?(registry, type)
      checksum = registry.send("project_#{type}_verification_checksum")
      last_verification_at = registry.send("project_#{type}_last_verification")
      last_successful_sync_at = registry.send("last_#{type}_successful_sync_at")

      checksum &&
        registry.project.last_repository_updated_at < 6.hours.ago &&
        !last_verification_at.nil? && last_verification_at > registry.project.last_repository_updated_at &&
        !last_successful_sync_at.nil? && last_successful_sync_at > registry.project.last_repository_updated_at
    end

    private

    def compare_checksum
      begin
        checksum = calculate_checksum(@registry.project.repository_storage, @registry.repository_path(@type))

        if checksum != @original_checksum
          record_status(nil, "#{@type.to_s.capitalize} checksum did not match")
        else
          record_status(checksum)
        end
      rescue Gitlab::Git::ChecksumVerificationError, Timeout::Error => e
        Rails.logger.error("#{self.class.name} - #{e.message}")
        record_status(nil, e.message)
      end
    end

    def calculate_checksum(storage, relative_path)
      Gitlab::Git::RepositoryChecksum.new(storage, relative_path)
    end

    def record_status(checksum: nil, error: nil)
      attrs = { "#{@type}_verification_checksum" => nil,
                "last_#{@type}_verification_at" => DateTime.now,
                "last_#{@type}_verification_failure" => nil }

      if checksum
        attrs["#{@type}_verification_checksum"] = checksum
      else
        attrs["last_#{@type}_verification_failure"] = error
      end

      @registry.update!(attrs)
    end

    def repository_exits?(type)
      case @type
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
