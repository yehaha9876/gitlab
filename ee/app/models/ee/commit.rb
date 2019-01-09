# frozen_string_literal: true

module EE
  module Commit
    extend ActiveSupport::Concern

    prepended do
      include Elastic::CommitsSearch
    end
  end
end
