class UserPathValidator < AbstractPathValidator
  extend Gitlab::EncodingHelper

  def self.path_regex
    Gitlab::PathRegex.root_namespace_path_regex
  end

  def self.format_regex
    Gitlab::PathRegex.namespace_format_regex
  end

  def self.format_error_message
    Gitlab::PathRegex.namespace_format_message
  end
end
