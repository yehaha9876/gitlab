namespace :plugins do
  desc 'Generate sceleton for new plugin'
  task generate: :environment do
    ARGV.each { |a| task a.to_sym { } }
    name = ARGV[1]

    unless name.present?
      puts 'Error. You need to specify a name for the plugin'
      exit 1
    end

    class_name = name.classify
    param = name.parameterize

    if Service.available_services_names.include?(param)
      puts 'Integration with such name is already availble in GitLab.'
      puts 'Check it out or choose a different name for your plugin.'
      exit 1
    end

    file_path = Rails.root.join('plugins', param + '_service.rb')

    template = File.read(Rails.root.join('generator_templates', 'plugins', 'template.rb'))
    template.gsub!('$NAME', class_name)
    template.gsub!('$PARAM', param)

    if File.write(file_path, template)
      puts "Done. Your plugin saved under #{file_path}."
      puts 'Feel free to edit it.'
    else
      puts "Failed to save #{file_path}."
    end
  end
end
