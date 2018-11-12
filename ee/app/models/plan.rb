class Plan < ActiveRecord::Base
  GL_COM_PAID_PLANS = %w[bronze silver gold]

  has_many :namespaces
end
