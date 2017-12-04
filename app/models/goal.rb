# Placeholder class for model that is implemented in EE
class Goal < ActiveRecord::Base
  prepend EE::Goal
end
