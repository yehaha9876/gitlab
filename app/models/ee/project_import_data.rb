module EE
  module ProjectImportData
    SSH_PRIVATE_KEY_OPTS = {
      type: 'RSA',
      bits: 4096
    }.freeze

    extend ActiveSupport::Concern

    included do
      validates :auth_method, inclusion: { in: %w[password ssh_public_key] }, allow_blank: true

      # We should generate a key even if there's no SSH URL present
      before_validation :generate_ssh_private_key!, if: ->(data) { data.auth_method == 'ssh_public_key' }
    end

    attr_accessor :regenerate_ssh_private_key

    def ssh_key_auth?
      ssh_import? && auth_method == 'ssh_public_key'
    end

    def ssh_import?
      project&.import_url&.start_with?('ssh://')
    end

    %i[auth_method user password ssh_private_key ssh_known_hosts ssh_known_hosts_verified_at ssh_known_hosts_verified_by_id].each do |name|
      define_method(name) do
        credentials[name] if credentials.present?
      end

      define_method("#{name}=") do |value|
        self.credentials ||= {}
        self.credentials[name] = value
      end
    end

    def ssh_known_hosts_verified_by
      @ssh_known_hosts_verified_by ||= ::User.find_by(id: ssh_known_hosts_verified_by_id)
    end

    def ssh_known_hosts_fingerprints
      ::SshHostKey.fingerprint_host_keys(ssh_known_hosts)
    end

    def ssh_public_key
      return nil unless ssh_private_key.present?

      comment = "git@#{::Gitlab.config.gitlab.host}"
      ::SSHKey.new(ssh_private_key, comment: comment).ssh_public_key
    end

    def generate_ssh_private_key!
      return if ssh_private_key.present? && !regenerate_ssh_private_key

      key = ::SSHKey.generate(SSH_PRIVATE_KEY_OPTS)
      self.ssh_private_key = key.private_key
    end
  end
end
