# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Sast
          SastParserError = Class.new(StandardError)

          def initialize(pipeline, type)
            @pipeline = pipeline
            @project = pipeline.project
            @type = type
            @scanners = {}
            @identifiers = {}
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
            scanner = create_scanner(data['scanner'] || mutate_scanner_tool(data['tool']))
            identifiers = create_identifiers(data['identifiers'])

            @project.vulnerabilities.build(
              pipeline: @pipeline,
              ref: @pipeline.ref,
              uuid: SecureRandom.uuid,
              report_type: @type,
              name: data['message'],
              primary_identifier_fingerprint: identifiers.first.fingerprint,
              project_fingerprint: generate_project_fingerprint(data['cve']),
              location_fingerprint: generate_location_fingerprint(data['location']),
              severity: parse_level(data['severity']),
              confidence: parse_level(data['confidence']),
              scanner: scanner,
              identifiers: identifiers,
              raw_metadata: data.to_json,
              metadata_version: "#{@type}:1.3" # hardcoded untill provided in the report
            )
          end

          def create_scanner(scanner)
            return unless scanner.is_a?(Hash) && !scanner.empty?

            @scanners[scanner['id']] ||= @project.vulnerability_scanners.build(
              external_id: scanner['id'],
              name: scanner['name'])
          end

          def create_identifiers(identifiers)
            return [] unless identifiers.is_a?(Array) && !identifiers.empty?

            identifiers.map do |identifier|
              create_identifier(identifier)
            end.compact
          end

          def create_identifier(identifier)
            return unless identifier.is_a?(Hash)

            fingerprint = generate_identifier_fingerprint(identifier)

            @identifiers[fingerprint] ||= @project.vulnerability_identifiers.build(
              external_type: identifier['type'],
              external_id: identifier['value'],
              name: identifier['name'],
              fingerprint: fingerprint,
              url: identifier['url'])
          end

          def mutate_scanner_tool(tool)
            { 'id' => tool, 'name' => tool.capitalize } if tool
          end

          def parse_level(input)
            input.blank? ? 'undefined' : input.downcase
          end

          def generate_location_fingerprint(location)
            Digest::SHA1.hexdigest("#{location['file']}:#{location['start_line']}:#{location['end_line']}")
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
