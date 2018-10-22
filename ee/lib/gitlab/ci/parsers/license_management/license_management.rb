# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module LicenseManagement
        class LicenseManagement
          LicenseManagementParserError = Class.new(StandardError)

          def parse!(json_data, license_management_report)
            root = JSON.parse(json_data)

            # Build a list of license objects containing their dependencies
            #puts root.to_yaml

            root['licenses'].each do |license_hash|
              license_expression = license_hash['name']
              puts "Found license expression #{license_expression}"

              LicenseManagement.each_license(license_expression) do |license_name|
                root['dependencies'].select do |dependency|
                  LicenseManagement.uses_license?(dependency['license']['name'], license_name)
                end.each do |dependency|
                  license_management_report.add_dependency(license_name, dependency['dependency']['name'])
                end
              end
            end


          rescue JSON::ParserError => e
            raise LicenseManagementParserError, "JSON parsing failed: #{e.message}"
          rescue => e
            raise LicenseManagementParserError, "License management report parsing failed: #{e.message}"
          end

          def self.remove_suffix(name)
            name.gsub(/-or-later$|-only$|\+$/, '')
          end

          def self.expression_to_list(expression)
            expression.split(',').map(&:strip).map { |name| LicenseManagement.remove_suffix(name) }
          end

          # Split the license expression when it is separated by spaces. Removes suffixes
          # specified in https://spdx.org/ids-how
          def self.each_license(expression)
            expression_to_list(expression).each do |license_name|
              yield(license_name)
            end
          end

          # Check that the license expression uses the given license name
          def self.uses_license?(expression, name)
            expression_to_list(expression).any? { |name1| name1.casecmp(LicenseManagement.remove_suffix(name)) == 0 }
          end
        end
      end
    end
  end
end
