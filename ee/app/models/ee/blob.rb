# frozen_string_literal: true

module EE
  module Blob
    extend ActiveSupport::Concern

    prepended do
      include Elastic::BlobsSearch
    end

    def owners
      @owners ||= ::Gitlab::CodeOwners.for_blob(self)
    end
  end
end
