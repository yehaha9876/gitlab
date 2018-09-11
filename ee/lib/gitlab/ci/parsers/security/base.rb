require 'gitlab/ci/parsers/base_parser'

module Gitlab
  module Ci
    module Parsers
      module Security
        class Base < ::Gitlab::Ci::Parsers::BaseParser

          def category
            self.class.file_type
          end

          def parse!(json_data, report)
            vulnerabilities = JSON.parse!(json_data)

            vulnerabilities.each do |vulnerability|
              report.add_vulnerability(create_vulnerability(vulnerability))
            end
          end

        protected

          def create_vulnerability(data)
            # TODO: add backward compatibility here?
            data['scanner'] = generate_scanner(data) if data['scanner'].nil?

            scanner = create_scanner(data['scanner'])
            location = create_location(data['location'])
            identifiers = create_identifiers(data['identifiers'])
            links = create_links(data['links'])

            ::Gitlab::Ci::Reports::Security::Vulnerabilities::Occurrence.new(
              category: category,
              name: data['message'],
              description: data['description'],
              compare_key: data['cve'], #FIXME: change that property name...
              severity: data['severity'],
              confidence: data['confidence'],
              solution: data['solution'],
              scanner: scanner,
              location: location,
              identifiers: identifiers,
              links: links,
              raw_metadata: data.to_json,
              metadata_version: "#{category}:1.0"
            )
          end

          def create_scanner(scanner)
            return nil unless scanner.is_a?(Hash) && !scanner.empty?

            ::Gitlab::Ci::Reports::Security::Vulnerabilities::Scanner.new(
              external_id: scanner['id'],
              name: scanner['name'],
            )
          end

          def create_location(location)
            return nil unless location.is_a?(Hash) && !location.empty?

            ::Gitlab::Ci::Reports::Security::Vulnerabilities::Location.new(
              file_path: location['file'],
              start_line: location['start_line'],
              end_line: location['end_line'],
              class_name: location['class_name'],
              method_name: location['method_name']
            )
          end

          def create_identifiers(identifiers)
            return [] unless identifiers.is_a?(Array) && !identifiers.empty?

            identifiers.map do |identifier|
              ::Gitlab::Ci::Reports::Security::Vulnerabilities::Identifier.new(
                external_type: identifier['type'],
                external_id: identifier['value'],
                name: identifier['name'],
                primary: identifier['primary'] == true,
                url: identifier['url']
              )
            end
          end

          def create_links(links)
            return [] unless links.is_a?(Array) && !links.empty?

            links.map do |link|
              ::Gitlab::Ci::Reports::Security::Vulnerabilities::Link.new(
                name: link['name'],
                url: link['url']
              )
            end
          end

          def generate_scanner(data)
            {
              id: data['tool'],
              name: data['tool'].capitalize
            }.with_indifferent_access
          end
        end
      end
    end
  end
end
