require "spec_helper"
require "chef/compliance/reporter/chef_server_automate"

describe Chef::Compliance::Reporter::ChefServerAutomate do
  before do
    # Isn't this already done globally in
    WebMock.disable_net_connect!

    Chef::Config[:client_key] = File.expand_path("../../../data/ssl/private_key.pem", __dir__)
    Chef::Config[:node_name] = "spec-node"
  end

  let(:reporter) { Chef::Compliance::Reporter::ChefServerAutomate.new(opts) }

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
      url: "https://chef.server/data_collector",
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

  let(:enriched_report) do
    {
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
              "code":
              "control 'tmp-1.0' do\n  impact 0.3\n  title 'A /tmp directory must exist'\n  desc 'A /tmp directory must exist'\n  describe file '/tmp' do\n    it { should be_directory }\n  end\nend\n",
              "source_location": { "ref": "/Users/vjeffrey/code/delivery/insights/data_generator/chef-client/cache/cookbooks/test-cookbook/recipes/../files/default/compliance_profiles/tmp_compliance_profile/controls/tmp.rb", "line": 3 },
              "id": "tmp-1.0",
              "results": [{ "status": "passed", "code_desc": "File /tmp should be directory", "run_time": 0.002312, "start_time": "2016-10-19 11:09:43 -0400" }],
            },
            {
              "title": "/tmp directory is owned by the root user",
              "desc": "The /tmp directory must be owned by the root user",
              "impact": 0.3,
              "refs": [{ "url": "https://pages.chef.io/rs/255-VFB-268/images/compliance-at-velocity2015.pdf", "ref": "Compliance Whitepaper" }],
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
          "groups": [{ "title": "/tmp Compliance Profile", "controls": ["tmp-1.0", "tmp-1.1"], "id": "controls/tmp.rb" }],
          "attributes": [{ "name": "syslog_pkg", "options": { "default": "rsyslog", "description": "syslog package..." } }],
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
    }
  end

  it "sends report successfully" do
    # TODO: Had to change 'X-Ops-Server-Api-Version' from 1 to 2, is that correct?
    report_stub = stub_request(:post, "https://chef.server/data_collector")
      .with(
        body: enriched_report,
        headers: {
          "X-Chef-Version" => Chef::VERSION,
          "X-Ops-Authorization-1" => /.+/,
          "X-Ops-Authorization-2" => /.+/,
          "X-Ops-Authorization-3" => /.+/,
          "X-Ops-Authorization-4" => /.+/,
          "X-Ops-Authorization-5" => /.+/,
          "X-Ops-Authorization-6" => /.+/,
          "X-Ops-Content-Hash" => "yfck5nQDcRWta06u45Q+J463LYY=",
          "X-Ops-Server-Api-Version" => "2",
          "X-Ops-Sign" => "algorithm=sha1;version=1.1;",
          "X-Ops-Timestamp" => /.+/,
          "X-Ops-Userid" => "spec-node",
          "X-Remote-Request-Id" => /.+/,
        }
      ).to_return(status: 200)

    expect(reporter.send_report(inspec_report)).to eq(true)

    expect(report_stub).to have_been_requested
  end

  describe "#validate_config!" do
    it "raises CMPL007 when entity_uuid is not present" do
      opts.delete(:entity_uuid)
      expect { reporter.validate_config! }.to raise_error(/^CMPL007/)
    end

    it "raises CMPL008 when run_id is not present" do
      opts.delete(:run_id)
      expect { reporter.validate_config! }.to raise_error(/^CMPL008/)
    end

    it "otherwise passes" do
      reporter.validate_config!
    end

  end

end
