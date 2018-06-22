class TokenResource < ActiveRecord::Base
  belongs_to :personal_access_token
  belongs_to :project
end
