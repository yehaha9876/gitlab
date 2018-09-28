# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Sast
          REPORT_TYPE = 'sast'
          SastParserError = Class.new(StandardError)

          def report_type
            REPORT_TYPE
          end

          def parse!(json_data, report)
            vulnerabilities = JSON.parse!(json_data)

            vulnerabilities.each do |vulnerability|
              report.add_vulnerability(create_vulnerability(vulnerability))
            end
          rescue JSON::ParserError
            raise SastParserError, "JSON parsing failed"
          rescue
            raise SastParserError, "SAST report parsing failed"
          end

          protected

          def create_vulnerability(data)
            # TODO: add backward compatibility here?
            data['scanner'] = generate_scanner(data) if data['scanner'].nil?

            scanner = create_scanner(data['scanner'])
            identifiers = create_identifiers(data['identifiers'])

            ::Vulnerabilities::Occurrence.new(
              report_type: report_type,
              name: data['message'],
              project_fingerprint: generate_project_fingerprint(data['cve']),
              primary_identifier_fingerprint: identifiers.first&.fingerprint,
              location_fingerprint: generate_location_fingerprint(data['location']),
              severity: parse_level(data['severity']),
              confidence: parse_level(data['confidence']),
              scanner: scanner,
              identifiers: identifiers,
              raw_metadata: data.to_json,
              metadata_version: "#{report_type}:1.3" # hardcoded untill provided in the report
            )
          end

          def create_scanner(scanner)
            return nil unless scanner.is_a?(Hash) && !scanner.empty?

            ::Vulnerabilities::Scanner.new(
              external_id: scanner['id'],
              name: scanner['name']
            )
          end

          def create_identifiers(identifiers)
            return [] unless identifiers.is_a?(Array) && !identifiers.empty?

            identifiers.map do |identifier|
              ::Vulnerabilities::Identifier.new(
                external_type: identifier['type'],
                external_id: identifier['value'],
                name: identifier['name'],
                fingerprint: generate_identifier_fingerprint(identifier),
                url: identifier['url']
              )
            end
          end

          def parse_level(input)
            input.blank? ? :undefined : input.downcase
          end

          def generate_scanner(data)
            {
              id: data['tool'],
              name: data['tool'].capitalize
            }.with_indifferent_access
          end

          def generate_location_fingerprint(location)
            Digest::SHA1.hexdigest "#{location['file_path']}:#{location['start_line']}:#{location['end_line']}"
          end

          def generate_project_fingerprint(compare_key)
            Digest::SHA1.hexdigest(compare_key)
          end

          def generate_identifier_fingerprint(identifier)
            Digest::SHA1.hexdigest "#{identifier['external_type']}:#{identifier['external_id']}"
          end
        end
      end
    end
  end
end
