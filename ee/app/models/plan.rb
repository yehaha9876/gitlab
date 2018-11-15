class Plan < ActiveRecord::Base
  GL_COM_PAID_PLANS = %w[bronze silver gold].freeze

  has_many :namespaces
end
