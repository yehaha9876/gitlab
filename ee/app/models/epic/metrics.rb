class Epic::Metrics < ApplicationRecord
  belongs_to :epic

  def record!
    self.save
  end
end
