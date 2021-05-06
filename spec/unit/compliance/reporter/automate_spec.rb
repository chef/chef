require "spec_helper"
require "json" # For .to_json

require "chef/compliance/reporter/automate"
describe Chef::Compliance::Reporter::Automate do
  let(:reporter) { Chef::Compliance::Reporter::Automate.new(opts) }

  let(:opts) do
    {
      entity_uuid: "aaaaaaaa-709a-475d-bef5-zzzzzzzzzzzz",
      run_id: "3f0536f7-3361-4bca-ae53-b45118dceb5d",
      node_info: {
        node: "chef-client.solo",
        environment: "My Prod Env",
        roles: %w{base_linux apache_linux},
        recipes: ["some_cookbook::some_recipe", "some_cookbook"],
        policy_name: "test_policy_name",
        policy_group: "test_policy_group",
        chef_tags: ["mylinux", "my.tag", "some=tag"],
        organization_name: "test_org",
        source_fqdn: "api.chef.io",
        ipaddress: "192.168.56.33",
        fqdn: "lb1.prod.example.com",
      },
      run_time_limit: 1.1,
      control_results_limit: 2,
      timestamp: Time.parse("2016-07-19T19:19:19+01:00"),
    }
  end

  let(:inspec_report) do
    {
      "version": "1.2.1",
      "profiles":
      [{ "name": "tmp_compliance_profile",
         "title": "/tmp Compliance Profile",
         "summary": "An Example Compliance Profile",
         "sha256": "7bd598e369970002fc6f2d16d5b988027d58b044ac3fa30ae5fc1b8492e215cd",
         "version": "0.1.1",
         "maintainer": "Nathen Harvey <nharvey@chef.io>",
         "license": "Apache 2.0 License",
         "copyright": "Nathen Harvey <nharvey@chef.io>",
         "supports": [],
         "controls":
         [{ "title": "A /tmp directory must exist",
            "desc": "A /tmp directory must exist",
            "impact": 0.3,
            "refs": [],
            "tags": {},
            "code": "control 'tmp-1.0' do\n  impact 0.3\n  title 'A /tmp directory must exist'\n  desc 'A /tmp directory must exist'\n  describe file '/tmp' do\n    it { should be_directory }\n  end\nend\n",
            "source_location": { "ref": "/Users/vjeffrey/code/delivery/insights/data_generator/chef-client/cache/cookbooks/test-cookbook/recipes/../files/default/compliance_profiles/tmp_compliance_profile/controls/tmp.rb", "line": 3 },
            "id": "tmp-1.0",
            "results": [
              { "status": "passed", "code_desc": "File /tmp should be directory", "run_time": 0.002312, "start_time": "2016-10-19 11:09:43 -0400" },
            ],
          },
          { "title": "/tmp directory is owned by the root user",
            "desc": "The /tmp directory must be owned by the root user",
            "impact": 0.3,
            "refs": [{ "url": "https://pages.chef.io/rs/255-VFB-268/images/compliance-at-velocity2015.pdf", "ref": "Compliance Whitepaper" }],
            "tags": { "production": nil, "development": nil, "identifier": "value", "remediation": "https://github.com/chef-cookbooks/audit" },
            "code": "control 'tmp-1.1' do\n  impact 0.3\n  title '/tmp directory is owned by the root user'\n  desc 'The /tmp directory must be owned by the root user'\n  tag 'production','development'\n  tag identifier: 'value'\n  tag remediation: 'https://github.com/chef-cookbooks/audit'\n  ref 'Compliance Whitepaper', url: 'https://pages.chef.io/rs/255-VFB-268/images/compliance-at-velocity2015.pdf'\n  describe file '/tmp' do\n    it { should be_owned_by 'root' }\n  end\nend\n",
            "source_location": { "ref": "/Users/vjeffrey/code/delivery/insights/data_generator/chef-client/cache/cookbooks/test-cookbook/recipes/../files/default/compliance_profiles/tmp_compliance_profile/controls/tmp.rb", "line": 12 },
            "id": "tmp-1.1",
            "results": [
              { "status": "passed", "code_desc": 'File /tmp should be owned by "root"', "run_time": 1.228845, "start_time": "2016-10-19 11:09:43 -0400" },
              { "status": "skipped", "code_desc": 'File /tmp should be owned by "root"', "run_time": 1.228845, "start_time": "2016-10-19 11:09:43 -0400" },
              { "status": "failed", "code_desc": "File /etc/hosts is expected to be directory", "run_time": 1.228845, "start_time": "2016-10-19 11:09:43 -0400", "message": "expected `File /etc/hosts.directory?` to return true, got false" },
            ],
          },
        ],
         "groups": [{ "title": "/tmp Compliance Profile", "controls": ["tmp-1.0", "tmp-1.1"], "id": "controls/tmp.rb" }],
         "attributes": [{ "name": "syslog_pkg", "options": { "default": "rsyslog", "description": "syslog package..." } }] }],
      "other_checks": [],
      "statistics": { "duration": 0.032332 },
    }
  end

  describe "#send_report" do
    before :each do
      WebMock.disable_net_connect!

      Chef::Config[:data_collector] = { token: token, server_url: "https://automate.test/data_collector" }
    end

    let(:token) { "fake_token" }

    it "sends report successfully to ChefAutomate with missing profiles" do
      metasearch_stub = stub_request(:post, "https://automate.test/compliance/profiles/metasearch")
        .with(
          body: '{"sha256": ["7bd598e369970002fc6f2d16d5b988027d58b044ac3fa30ae5fc1b8492e215cd"]}',
          headers: {
            "Accept-Encoding" => "identity",
            "X-Chef-Version" => Chef::VERSION,
            "X-Data-Collector-Auth" => "version=1.0",
            "X-Data-Collector-Token" => token,
          }
        ).to_return(
          status: 200,
          body: '{"missing_sha256": ["7bd598e369970002fc6f2d16d5b988027d58b044ac3fa30ae5fc1b8492e215cd"]}'
        )

      report_stub = stub_request(:post, "https://automate.test/data_collector")
        .with(
          body: {
            "version": "1.2.1",
            "profiles": [
              {
                "name": "tmp_compliance_profile",
                "title": "/tmp Compliance Profile",
                "summary": "An Example Compliance Profile",
                "sha256": "7bd598e369970002fc6f2d16d5b988027d58b044ac3fa30ae5fc1b8492e215cd",
                "version": "0.1.1",
                "maintainer": "Nathen Harvey <nharvey@chef.io>",
                "license": "Apache 2.0 License",
                "copyright": "Nathen Harvey <nharvey@chef.io>",
                "supports": [],
                "controls": [
                  {
                    "title": "A /tmp directory must exist",
                    "desc": "A /tmp directory must exist",
                    "impact": 0.3,
                    "refs": [],
                    "tags": {},
                    "code": "control 'tmp-1.0' do\n  impact 0.3\n  title 'A /tmp directory must exist'\n  desc 'A /tmp directory must exist'\n  describe file '/tmp' do\n    it { should be_directory }\n  end\nend\n",
                    "source_location": { "ref": "/Users/vjeffrey/code/delivery/insights/data_generator/chef-client/cache/cookbooks/test-cookbook/recipes/../files/default/compliance_profiles/tmp_compliance_profile/controls/tmp.rb", "line": 3 },
                    "id": "tmp-1.0",
                    "results": [
                      { "status": "passed", "code_desc": "File /tmp should be directory", "run_time": 0.002312, "start_time": "2016-10-19 11:09:43 -0400" },
                    ],
                  },
                  {
                    "title": "/tmp directory is owned by the root user",
                    "desc": "The /tmp directory must be owned by the root user",
                    "impact": 0.3,
                    "refs": [
                      { "url": "https://pages.chef.io/rs/255-VFB-268/images/compliance-at-velocity2015.pdf", "ref": "Compliance Whitepaper" },
                    ],
                    "tags": { "production": nil, "development": nil, "identifier": "value", "remediation": "https://github.com/chef-cookbooks/audit" },
                    "code": "control 'tmp-1.1' do\n  impact 0.3\n  title '/tmp directory is owned by the root user'\n  desc 'The /tmp directory must be owned by the root user'\n  tag 'production','development'\n  tag identifier: 'value'\n  tag remediation: 'https://github.com/chef-cookbooks/audit'\n  ref 'Compliance Whitepaper', url: 'https://pages.chef.io/rs/255-VFB-268/images/compliance-at-velocity2015.pdf'\n  describe file '/tmp' do\n    it { should be_owned_by 'root' }\n  end\nend\n",
                    "source_location": { "ref": "/Users/vjeffrey/code/delivery/insights/data_generator/chef-client/cache/cookbooks/test-cookbook/recipes/../files/default/compliance_profiles/tmp_compliance_profile/controls/tmp.rb", "line": 12 },
                    "id": "tmp-1.1",
                    "results": [
                      { "status": "failed", "code_desc": "File /etc/hosts is expected to be directory", "run_time": 1.228845, "start_time": "2016-10-19 11:09:43 -0400", "message": "expected `File /etc/hosts.directory?` to return true, got false" },
                      { "status": "skipped", "code_desc": 'File /tmp should be owned by "root"', "run_time": 1.228845, "start_time": "2016-10-19 11:09:43 -0400" },
                    ],
                    "removed_results_counts": { "failed": 0, "skipped": 0, "passed": 1 },
                  },
                ],
                "groups": [
                  { "title": "/tmp Compliance Profile", "controls": ["tmp-1.0", "tmp-1.1"], "id": "controls/tmp.rb" },
                ],
                "attributes": [
                  { "name": "syslog_pkg", "options": { "default": "rsyslog", "description": "syslog package..." } },
                ],
              },
            ],
            "other_checks": [],
            "statistics": { "duration": 0.032332 },
            "type": "inspec_report",
            "node_name": "chef-client.solo",
            "end_time": "2016-07-19T18:19:19Z",
            "node_uuid": "aaaaaaaa-709a-475d-bef5-zzzzzzzzzzzz",
            "environment": "My Prod Env",
            "roles": %w{base_linux apache_linux},
            "recipes": ["some_cookbook::some_recipe", "some_cookbook"],
            "report_uuid": "3f0536f7-3361-4bca-ae53-b45118dceb5d",
            "source_fqdn": "api.chef.io",
            "organization_name": "test_org",
            "policy_group": "test_policy_group",
            "policy_name": "test_policy_name",
            "chef_tags": ["mylinux", "my.tag", "some=tag"],
            "ipaddress": "192.168.56.33",
            "fqdn": "lb1.prod.example.com",
            "run_time_limit": 1.1,
          },
          headers: {
            "Accept-Encoding" => "identity",
            "X-Chef-Version" => Chef::VERSION,
            "X-Data-Collector-Auth" => "version=1.0",
            "X-Data-Collector-Token" => token,
          }
        ).to_return(status: 200)

      expect(reporter.send_report(inspec_report)).to eq(true)

      expect(metasearch_stub).to have_been_requested
      expect(report_stub).to have_been_requested
    end

    it "sends report successfully to ChefAutomate with seen profiles" do
      metasearch_stub = stub_request(:post, "https://automate.test/compliance/profiles/metasearch")
        .with(
          body: '{"sha256": ["7bd598e369970002fc6f2d16d5b988027d58b044ac3fa30ae5fc1b8492e215cd"]}',
          headers: {
            "Accept-Encoding" => "identity",
            "X-Chef-Version" => Chef::VERSION,
            "X-Data-Collector-Auth" => "version=1.0",
            "X-Data-Collector-Token" => token,
          }
        ).to_return(
          status: 200,
          body: '{"missing_sha256": []}'
        )

      report_stub = stub_request(:post, "https://automate.test/data_collector")
        .with(
          body: {
            "version": "1.2.1",
            "profiles": [
              {
                "title": "/tmp Compliance Profile",
                "sha256": "7bd598e369970002fc6f2d16d5b988027d58b044ac3fa30ae5fc1b8492e215cd",
                "version": "0.1.1",
                "controls": [
                  {
                    "id": "tmp-1.0",
                    "results": [
                      { "status": "passed", "code_desc": "File /tmp should be directory" },
                    ],
                  },
                  {
                    "id": "tmp-1.1",
                    "results": [
                      { "status": "failed", "code_desc": "File /etc/hosts is expected to be directory", "run_time": 1.228845, "start_time": "2016-10-19 11:09:43 -0400", "message": "expected `File /etc/hosts.directory?` to return true, got false" },
                      { "status": "skipped", "code_desc": 'File /tmp should be owned by "root"', "run_time": 1.228845, "start_time": "2016-10-19 11:09:43 -0400" },
                    ],
                    "removed_results_counts": { "failed": 0, "skipped": 0, "passed": 1 },
                  },
                ],
                "attributes": [
                  { "name": "syslog_pkg", "options": { "default": "rsyslog", "description": "syslog package..." } },
                ],
              },
            ],
            "other_checks": [],
            "statistics": { "duration": 0.032332 },
            "type": "inspec_report",
            "node_name": "chef-client.solo",
            "end_time": "2016-07-19T18:19:19Z",
            "node_uuid": "aaaaaaaa-709a-475d-bef5-zzzzzzzzzzzz",
            "environment": "My Prod Env",
            "roles": %w{base_linux apache_linux},
            "recipes": ["some_cookbook::some_recipe", "some_cookbook"],
            "report_uuid": "3f0536f7-3361-4bca-ae53-b45118dceb5d",
            "source_fqdn": "api.chef.io",
            "organization_name": "test_org",
            "policy_group": "test_policy_group",
            "policy_name": "test_policy_name",
            "chef_tags": ["mylinux", "my.tag", "some=tag"],
            "ipaddress": "192.168.56.33",
            "fqdn": "lb1.prod.example.com",
            "run_time_limit": 1.1,
          },
          headers: {
            "Accept-Encoding" => "identity",
            "X-Chef-Version" => Chef::VERSION,
            "X-Data-Collector-Auth" => "version=1.0",
            "X-Data-Collector-Token" => token,
          }
        ).to_return(status: 200)

      expect(reporter.send_report(inspec_report)).to eq(true)

      expect(metasearch_stub).to have_been_requested
      expect(report_stub).to have_been_requested
    end
  end

  describe "#validate_config!" do
    it "raises CMPL004 when entity_uuid is not present" do
      opts.delete(:entity_uuid)
      expect { reporter.validate_config! }.to raise_error(/^CMPL004/)
    end

    it "raises CMPL005 when run_id is not present" do
      opts.delete(:run_id)
      expect { reporter.validate_config! }.to raise_error(/^CMPL005/)
    end

    it "raises CMPL006 when data collector URL is missing" do
      Chef::Config[:data_collector] = { token: "not_nil", server_url: nil }
      reporter = Chef::Compliance::Reporter::Automate.new(opts)
      expect { reporter.validate_config! }.to raise_error(/^CMPL006/)
    end

    it "raises CMPL006 when data collector token is missing" do
      Chef::Config[:data_collector] = { token: nil, server_url: "not_nil" }
      reporter = Chef::Compliance::Reporter::Automate.new(opts)
      expect { reporter.validate_config! }.to raise_error(/^CMPL006/)
    end

    it "otherwise passes" do
      Chef::Config[:data_collector] = { token: "not_nil", server_url: "not_nil" }
      reporter.validate_config!
    end
  end

  describe "#truncate_controls_results" do
    let(:report) do
      {
        "version": "1.2.1",
        "profiles":
        [{ "name": "tmp_compliance_profile",
           "title": "/tmp Compliance Profile",
           "summary": "An Example Compliance Profile",
           "sha256": "7bd598e369970002fc6f2d16d5b988027d58b044ac3fa30ae5fc1b8492e215ff",
           "version": "0.1.1",
           "maintainer": "Nathen Harvey <nharvey@chef.io>",
           "license": "Apache 2.0 License",
           "copyright": "Nathen Harvey <nharvey@chef.io>",
           "supports": [],
           "controls":
           [{ "id": "tmp-2.0",
              "title": "A bunch of directories must exist",
              "desc": "A bunch of directories must exist for testing",
              "impact": 0.3,
              "refs": [],
              "tags": {},
              "code": "control 'tmp-2.0' do\n  impact 0.3\n  title 'A bunch of directories must exist'\n  desc 'A bunch of directories must exist for testing'\n  describe file '/tmp' do\n    it { should be_directory }\n  end\nend\n",
              "source_location": { "ref": "/Users/vjeffrey/code/delivery/insights/data_generator/chef-client/cache/cookbooks/test-cookbook/recipes/../files/default/compliance_profiles/tmp_compliance_profile/controls/tmp.rb", "line": 3 },
              "results": [
                { "status": "passed", "code_desc": "File /tmp should be directory", "run_time": 0.002312, "start_time": "2016-10-19 11:09:43 -0400" },
                { "status": "passed", "code_desc": "File /etc should be directory", "run_time": 0.002314, "start_time": "2016-10-19 11:09:45 -0400" },
                { "status": "passed", "code_desc": "File /opt should be directory", "run_time": 0.002315, "start_time": "2016-10-19 11:09:46 -0400" },
                { "status": "skipped", "code_desc": "No-op", "run_time": 0.002316, "start_time": "2016-10-19 11:09:44 -0400", "skip_message": "4 testing" },
                { "status": "skipped", "code_desc": "No-op", "run_time": 0.002317, "start_time": "2016-10-19 11:09:44 -0400", "skip_message": "4 testing" },
                { "status": "skipped", "code_desc": "No-op", "run_time": 0.002318, "start_time": "2016-10-19 11:09:44 -0400", "skip_message": "4 testing" },
                { "status": "failed", "code_desc": "File /etc/passwd should be directory", "run_time": 0.002313, "start_time": "2016-10-19 11:09:44 -0400" },
                { "status": "failed", "code_desc": "File /etc/passwd should be directory", "run_time": 0.002313, "start_time": "2016-10-19 11:09:44 -0400" },
                { "status": "failed", "code_desc": "File /etc/passwd should be directory", "run_time": 0.002313, "start_time": "2016-10-19 11:09:44 -0400" },
              ],
            },
            { "id": "tmp-2.1",
              "title": "/tmp directory is owned by the root user",
              "desc": "The /tmp directory must be owned by the root user",
              "impact": 0.3,
              "refs": [{ "url": "https://pages.chef.io/rs/255-VFB-268/images/compliance-at-velocity2015.pdf", "ref": "Compliance Whitepaper" }],
              "tags": { "production": nil, "development": nil, "identifier": "value", "remediation": "https://github.com/chef-cookbooks/audit" },
              "code": "control 'tmp-2.1' do\n  impact 0.3\n  title '/tmp directory is owned by the root user'\n  desc 'The /tmp directory must be owned by the root user'\n  tag 'production','development'\n  tag identifier: 'value'\n  tag remediation: 'https://github.com/chef-cookbooks/audit'\n  ref 'Compliance Whitepaper', url: 'https://pages.chef.io/rs/255-VFB-268/images/compliance-at-velocity2015.pdf'\n  describe file '/tmp' do\n    it { should be_owned_by 'root' }\n  end\nend\n",
              "source_location": { "ref": "/Users/vjeffrey/code/delivery/insights/data_generator/chef-client/cache/cookbooks/test-cookbook/recipes/../files/default/compliance_profiles/tmp_compliance_profile/controls/tmp.rb", "line": 12 },
              "results": [
                { "status": "passed", "code_desc": 'File /tmp should be owned by "root"', "run_time": 1.228845, "start_time": "2016-10-19 11:09:43 -0400" },
                { "status": "passed", "code_desc": 'File /etc should be owned by "root"', "run_time": 1.238845, "start_time": "2016-10-19 11:09:43 -0400" },
              ],
            },
          ],
           "groups": [{ "title": "/tmp Compliance Profile", "controls": ["tmp-1.0", "tmp-1.1"], "id": "controls/tmp.rb" }],
           "attributes": [{ "name": "syslog_pkg", "options": { "default": "rsyslog", "description": "syslog package..." } }] }],
        "other_checks": [],
        "statistics": { "duration": 0.032332 },
      }
    end

    it "truncates controls results 1" do
      truncated_report = reporter.truncate_controls_results(report, 5)
      expect(truncated_report[:profiles][0][:controls][0][:results].length).to eq(5)
      statuses = truncated_report[:profiles][0][:controls][0][:results].map { |r| r[:status] }
      expect(statuses).to eq(%w{failed failed failed skipped skipped})
      expect(truncated_report[:profiles][0][:controls][0][:removed_results_counts]).to eq(failed: 0, skipped: 1, passed: 3)
    end

    it "truncates controls results 2" do
      truncated_report = reporter.truncate_controls_results(report, 5)
      expect(truncated_report[:profiles][0][:controls][1][:results].length).to eq(2)
      statuses = truncated_report[:profiles][0][:controls][1][:results].map { |r| r[:status] }
      expect(statuses).to eq(%w{passed passed})
      expect(truncated_report[:profiles][0][:controls][1][:removed_results_counts]).to eq(nil)
    end

    it "truncates controls results 3" do
      truncated_report = reporter.truncate_controls_results(report, 0)
      expect(truncated_report[:profiles][0][:controls][0][:results].length).to eq(9)
    end

    it "truncates controls results 4" do
      truncated_report = reporter.truncate_controls_results(report, 1)
      expect(truncated_report[:profiles][0][:controls][0][:results].length).to eq(1)
    end
  end

  describe "#strip_profiles_meta" do
    it "removes the metadata from seen profiles" do
      expected = {
        other_checks: [],
        profiles: [
          {
            attributes: [
              {
                name: "syslog_pkg",
                options: {
                  default: "rsyslog",
                  description: "syslog package...",
                },
              },
            ],
            controls: [
              {
                id: "tmp-1.0",
                results: [
                  {
                    code_desc: "File /tmp should be directory",
                    status: "passed",
                  },
                ],
              },
              {
                id: "tmp-1.1",
                results: [
                  {
                    code_desc: 'File /tmp should be owned by "root"',
                    run_time: 1.228845,
                    start_time: "2016-10-19 11:09:43 -0400",
                    status: "passed",
                  },
                  {
                    code_desc: 'File /tmp should be owned by "root"',
                    run_time: 1.228845,
                    start_time: "2016-10-19 11:09:43 -0400",
                    status: "skipped",
                  },
                  {
                    code_desc: "File /etc/hosts is expected to be directory",
                    message: "expected `File /etc/hosts.directory?` to return true, got false",
                    run_time: 1.228845,
                    start_time: "2016-10-19 11:09:43 -0400",
                    status: "failed",
                  },
                ],
              },
            ],
            sha256: "7bd598e369970002fc6f2d16d5b988027d58b044ac3fa30ae5fc1b8492e215cd",
            title: "/tmp Compliance Profile",
            version: "0.1.1",
          },
        ],
        run_time_limit: 1.1,
        statistics: {
          duration: 0.032332,
        },
        version: "1.2.1",
      }
      expect(reporter.strip_profiles_meta(inspec_report, [], 1.1)).to eq(expected)
    end

    it "does not remove the metadata from missing profiles" do
      expected = inspec_report.merge(run_time_limit: 1.1)
      expect(reporter.strip_profiles_meta(inspec_report, ["7bd598e369970002fc6f2d16d5b988027d58b044ac3fa30ae5fc1b8492e215cd"], 1.1)).to eq(expected)
    end
  end
end
