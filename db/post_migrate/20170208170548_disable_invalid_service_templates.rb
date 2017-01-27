class DisableInvalidServiceTemplates < ActiveRecord::Migration
  DOWNTIME = false

  if defined?(Service).nil?
    class Service < ActiveRecord::Base
      self.inheritance_column = nil
    end
  end

  def up
    Service.where(template: true, active: true).each do |template|
      template.update(active: false) unless template.valid?
    end
  end
end
