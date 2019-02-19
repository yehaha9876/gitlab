# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::ContainerScanning do
  let(:parser) { described_class.new }

  let(:clair_vulnerabilities) do
    JSON.parse!(
      File.read(
        Rails.root.join('spec/fixtures/security-reports/master/gl-container-scanning-report.json')
      )
    )['vulnerabilities']
  end

  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:artifact) { create(:ee_ci_job_artifact, :container_scanning) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type) }

    before do
      artifact.each_blob do |blob|
        parser.parse!(blob, report)
      end
    end

    it "parses all identifiers and occurrences for unapproved vulnerabilities" do
      expect(report.occurrences.length).to eq(8)
      expect(report.identifiers.length).to eq(8)
      expect(report.scanners.length).to eq(1)
    end

    it "generates expected location fingerprint" do
      expected = Digest::SHA1.hexdigest('debian:9:glibc')

      expect(report.occurrences.first[:location_fingerprint]).to eq(expected)
    end

    it "generates expected metadata_version" do
      expect(report.occurrences.first[:metadata_version]).to eq('1.3')
    end

    it "adds report image's name to raw_metadata" do
      expect(JSON.parse(report.occurrences.first[:raw_metadata]).dig('location', 'image'))
        .to eq('registry.gitlab.com/groulot/container-scanning-test/master:5f21de6956aee99ddb68ae49498662d9872f50ff')
    end
  end

  describe '#format_vulnerability' do
    it 'format ZAP vulnerability into the 1.3 format' do
      expect(parser.send(:format_vulnerability, clair_vulnerabilities[0], 'image_name')).to eq( {
        'category' => 'container_scanning',
        'message' => 'CVE-2017-18269 in glibc',
        'confidence' => 'Medium',
        'cve' => 'CVE-2017-18269',
        'identifiers' => [
          {
            'type' => 'cve',
            'name' => 'CVE-2017-18269',
            'value' => 'CVE-2017-18269',
            'url' => 'https://security-tracker.debian.org/tracker/CVE-2017-18269'
          }
        ],
        'location' => {
          'image' => 'image_name',
          'operating_system' => 'debian:9',
          'dependency' => {
            'package' => {
              'name' => 'glibc'
            },
            'version' => '2.24-11+deb9u3'
          }
        },
        'links' => [{ 'url' => 'https://security-tracker.debian.org/tracker/CVE-2017-18269' }],
        'description' => 'SSE2-optimized memmove implementation problem.',
        'priority' => 'Unknown',
        'scanner' => { 'id' => 'clair', 'name' => 'Clair' },
        'severity' => 'critical',
        'solution' => 'Upgrade glibc from 2.24-11+deb9u3 to 2.24-11+deb9u4',
        'tool' => 'clair',
        'url' => 'https://security-tracker.debian.org/tracker/CVE-2017-18269'
      } )
    end
  end

  describe '#translate_severity' do
    context 'with recognised values' do
      using RSpec::Parameterized::TableSyntax

      where(:severity, :expected) do
        'Unknown'    | 'unknown'
        'Negligible' | 'low'
        'Low'        | 'low'
        'Medium'     | 'medium'
        'High'       | 'high'
        'Critical'   | 'critical'
        'Defcon1'    | 'critical'
      end

      with_them do
        it "translate severity from Clair" do
          expect(parser.send(:translate_severity, severity)).to eq(expected)
        end
      end
    end

    context 'with a wrong value' do
      it 'throws an exception' do
        expect { parser.send(:translate_severity, 'abcd<efg>') }.to raise_error(
          ::Gitlab::Ci::Parsers::Security::Common::SecurityReportParserError,
          'Unknown severity in container scanning report: abcd&lt;efg&gt;'
        )
      end
    end
  end

  describe '#message' do
    subject { parser.send(:message, input)}

    context 'when there is a featurename' do
      let(:input) do
        {
          "featurename" => "foo",
          "featureversion" => "",
          "vulnerability" => "CVE-2018-777",
          "namespace" => "debian:9",
          "description" => "CVE-2018-777 is affecting your system",
          "link" => "https://security-tracker.debian.org/tracker/CVE-2018-777",
          "severity" => "Unknown",
          "fixedby" => "1.4"
        }
      end

      it 'formats message correctly ' do
        is_expected.to eq('CVE-2018-777 in foo')
      end
    end

    context 'when there is a no featurename' do
      let(:input) do
        {
          "featurename" => "",
          "featureversion" => "",
          "vulnerability" => "CVE-2018-777",
          "namespace" => "debian:9",
          "description" => "CVE-2018-777 is affecting your system",
          "link" => "https://security-tracker.debian.org/tracker/CVE-2018-777",
          "severity" => "Unknown",
          "fixedby" => "1.4"
        }
      end

      it 'formats message correctly' do
        is_expected.to eq('CVE-2018-777')
      end
    end
  end

  describe '#description' do
    subject { parser.send(:description, input) }

    context 'when there is a description' do
      let(:input) do
        {
          "featurename" => "",
          "featureversion" => "",
          "vulnerability" => "CVE-2018-777",
          "namespace" => "debian:9",
          "description" => "SSE2-optimized memmove implementation problem.",
          "link" => "https://security-tracker.debian.org/tracker/CVE-2018-777",
          "severity" => "Unknown",
          "fixedby" => "1.4"
        }
      end

      it 'formats description correctly ' do
        is_expected.to eq('SSE2-optimized memmove implementation problem.')
      end
    end

    context 'when there is no description and no featurename' do
      let(:input) do
        {
          "featurename" => "",
          "featureversion" => "",
          "vulnerability" => "CVE-2018-777",
          "namespace" => "debian:9",
          "description" => "",
          "link" => "https://security-tracker.debian.org/tracker/CVE-2018-777",
          "severity" => "Unknown",
          "fixedby" => "1.4"
        }
      end

      it 'formats description correctly ' do
        is_expected.to eq('debian:9 is affected by CVE-2018-777')
      end
    end

    context 'when there is no description and no featureversion but featurename is present' do
      let(:input) do
        {
          "featurename" => "foo",
          "featureversion" => "",
          "vulnerability" => "CVE-2018-777",
          "namespace" => "debian:9",
          "description" => "",
          "link" => "https://security-tracker.debian.org/tracker/CVE-2018-777",
          "severity" => "Unknown",
          "fixedby" => "1.4"
        }
      end

      it 'formats description correctly ' do
        is_expected.to eq('foo is affected by CVE-2018-777')
      end
    end

    context 'when there is no description but featurename and featureversion are present' do
      let(:input) do
        {
          "featurename" => "foo",
          "featureversion" => "1.2.3",
          "vulnerability" => "CVE-2018-777",
          "namespace" => "debian:9",
          "description" => "",
          "link" => "https://security-tracker.debian.org/tracker/CVE-2018-777",
          "severity" => "Unknown",
          "fixedby" => "1.4"
        }
      end

      it 'formats description correctly ' do
        is_expected.to eq('foo:1.2.3 is affected by CVE-2018-777')
      end
    end
  end

  describe '#solution' do
    subject { parser.send(:solution, input) }

    context 'without a fixedby value' do
      let(:input) do
        {
          "featurename" => "foo",
          "featureversion" => "1.2.3",
          "vulnerability" => "CVE-2018-777",
          "namespace" => "debian:9",
          "description" => "",
          "link" => "https://security-tracker.debian.org/tracker/CVE-2018-777",
          "severity" => "Unknown",
          "fixedby" => ""
        }
      end

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when there is a fixedby but no featurename' do
      let(:input) do
        {
          "featurename" => "",
          "featureversion" => "1.2.3",
          "vulnerability" => "CVE-2018-777",
          "namespace" => "debian:9",
          "description" => "",
          "link" => "https://security-tracker.debian.org/tracker/CVE-2018-777",
          "severity" => "Unknown",
          "fixedby" => "1.4"
        }
      end

      it 'formats solution correctly ' do
        is_expected.to eq('Upgrade to 1.4')
      end
    end

    context 'when there is a fixedby, a featurename but no featureversion' do
      let(:input) do
        {
          "featurename" => "foo",
          "featureversion" => "",
          "vulnerability" => "CVE-2018-777",
          "namespace" => "debian:9",
          "description" => "",
          "link" => "https://security-tracker.debian.org/tracker/CVE-2018-777",
          "severity" => "Unknown",
          "fixedby" => "1.4"
        }
      end

      it 'formats solution correctly ' do
        is_expected.to eq('Upgrade foo to 1.4')
      end
    end

    context 'when there is a fixedby, a featurename and a featureversion' do
      let(:input) do
        {
          "featurename" => "foo",
          "featureversion" => "1.2.3",
          "vulnerability" => "CVE-2018-777",
          "namespace" => "debian:9",
          "description" => "",
          "link" => "https://security-tracker.debian.org/tracker/CVE-2018-777",
          "severity" => "Unknown",
          "fixedby" => "1.4"
        }
      end

      it 'formats solution correctly ' do
        is_expected.to eq('Upgrade foo from 1.2.3 to 1.4')
      end
    end
  end
end
