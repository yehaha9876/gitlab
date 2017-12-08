# Load external services from /plugins directory
# and set into PLUGINS variable
files = Rails.root.join('plugins', '*_service.rb')

PLUGINS = Dir.glob(files).map do |file|
  File.basename(file).sub('_service.rb', '')
end
