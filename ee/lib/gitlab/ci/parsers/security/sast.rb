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

          def parse!(report, json_data)
            vulnerabilities = JSON.parse!(json_data)

            vulnerabilities.each do |vulnerability|
              create_vulnerability(report, vulnerability)
            end
          rescue JSON::ParserError
            raise SastParserError, "JSON parsing failed"
          rescue
            raise SastParserError, "SAST report parsing failed"
          end

          protected

          def create_vulnerability(report, data)
            scanner = create_scanner(report, data['scanner'] || mutate_scanner_tool(data['tool']))
            identifiers = create_identifiers(report, data['identifiers'])

            report.add_occurrence(
              report_type: report_type,
              name: data['message'],
              primary_identifier_fingerprint: identifiers.first,
              project_fingerprint: generate_project_fingerprint(data['cve']),
              location_fingerprint: generate_location_fingerprint(data['location']),
              severity: parse_level(data['severity']),
              confidence: parse_level(data['confidence']),
              scanner: scanner,
              identifiers: identifiers,
              raw_metadata: data.to_json,
              metadata_version: "#{report_type}:1.3" # hardcoded untill provided in the report
            )
          end

          def create_scanner(report, scanner)
            report.add_scanner(
              external_id: scanner['id'],
              name: scanner['name'])
          end

          def create_identifiers(report, identifiers)
            return unless identifiers.is_a?(Array)

            identifiers.map do |identifier|
              create_identifier(report, identifier)
            end
          end

          def create_identifier(report, identifier)
            return unless identifier.is_a?(Hash)

            report.add_identifier(
              external_type: identifier['type'],
              external_id: identifier['value'],
              name: identifier['name'],
              fingerprint: generate_identifier_fingerprint(identifier),
              url: identifier['url'])
          end

          def mutate_scanner_tool(tool)
            { 'id' => tool, 'name' => tool.capitalize } if tool
          end

          def parse_level(input)
            input.blank? ? :undefined : input.downcase
          end

          def generate_location_fingerprint(location)
            Digest::SHA1.hexdigest("#{location['file_path']}:#{location['start_line']}:#{location['end_line']}")
          end

          def generate_project_fingerprint(compare_key)
            Digest::SHA1.hexdigest(compare_key)
          end

          def generate_identifier_fingerprint(identifier)
            Digest::SHA1.hexdigest("#{identifier['type']}:#{identifier['value']}")
          end
        end
      end
    end
  end
end
