# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class ContainerScanning < Common
          include Security::Concerns::DeprecatedSyntax

          DEPRECATED_REPORT_VERSION = "1.3".freeze

          def parse!(json_data, report)
            vulnerabilities = format_report(JSON.parse!(json_data))

            vulnerabilities.each do |vulnerability|
              create_vulnerability(report, vulnerability, DEPRECATED_REPORT_VERSION)
            end
          rescue JSON::ParserError
            raise SecurityReportParserError, 'JSON parsing failed'
          rescue
            raise SecurityReportParserError, "#{report.type} security report parsing failed"
          end

          private

          # Transforms the Clair JSON report into the expected format
          def format_report(data)
            vulnerabilities = data['vulnerabilities']
            unapproved = data['unapproved']
            results = []

            vulnerabilities.each do |vulnerability|
              # We only report unapproved vulnerabilities
              next unless unapproved.include?(vulnerability['vulnerability'])

              results.append(format_vulnerability(vulnerability, data['image']))
            end

            results
          end

          def format_vulnerability(vulnerability, image)
            {
              'category' => 'container_scanning',
              'message' => message(vulnerability),
              'description' => description(vulnerability),
              'cve' => vulnerability['vulnerability'],
              'severity' => translate_severity(vulnerability['severity']),
              'solution' => solution(vulnerability),
              'confidence' => 'Medium',
              'location' => {
                'image' => image,
                'operating_system' => vulnerability["namespace"],
                'dependency' => {
                  'package' => {
                    'name' => vulnerability["featurename"]
                  },
                  'version' => vulnerability["featureversion"]
                }
              },
              'scanner' => { 'id' => 'clair', 'name' => 'Clair' },
              'identifiers' => [
                {
                  'type' => 'cve',
                  'name' => vulnerability['vulnerability'],
                  'value' => vulnerability['vulnerability'],
                  'url' => vulnerability['link']
                }
              ],
              'links' => [{ 'url' => vulnerability['link'] }],
              'priority' => 'Unknown',
              'url' => vulnerability['link'],
              'tool' => 'clair'
            }
          end

          def translate_severity(severity)
            case severity
            when 'Negligible'
              'low'
            when 'Unknown', 'Low', 'Medium', 'High', 'Critical'
              severity.downcase
            when 'Defcon1'
              'critical'
            else
              safe_severity = ERB::Util.html_escape(severity)
              raise SecurityReportParserError, "Unknown severity in container scanning report: #{safe_severity}"
            end
          end

          def solution(vulnerability)
            return if vulnerability['fixedby'].blank?

            return "Upgrade to #{vulnerability['fixedby']}" if vulnerability['featurename'].blank?

            return "Upgrade #{vulnerability['featurename']} to #{vulnerability['fixedby']}" if vulnerability['featureversion'].blank?

            return "Upgrade #{vulnerability['featurename']} from #{vulnerability['featureversion']} to #{vulnerability['fixedby']}"
          end

          def message(vulnerability)
            return vulnerability['vulnerability'] if vulnerability['featurename'].blank?

            "#{vulnerability['vulnerability']} in #{vulnerability['featurename']}"
          end

          def description(vulnerability)
            return vulnerability['description'] unless vulnerability['description'].blank?

            suffix = "is affected by #{vulnerability['vulnerability']}"

            return "#{vulnerability['namespace']} #{suffix}" if vulnerability['featurename'].blank?

            return "#{vulnerability['featurename']} #{suffix}" if vulnerability['featureversion'].blank?

            "#{vulnerability['featurename']}:#{vulnerability['featureversion']} #{suffix}"
          end

          def generate_location_fingerprint(location)
            Digest::SHA1.hexdigest("#{location['operating_system']}:#{location.dig('dependency', 'package', 'name')}")
          end
        end
      end
    end
  end
end
