
require "spec_helper"

# Stubs a basic client object
shared_context "client" do
  let(:fqdn)             { "hostname.example.org" }
  let(:hostname)         { "hostname" }
  let(:machinename)      { "machinename.example.org" }
  let(:platform)         { "example-platform" }
  let(:platform_version) { "example-platform-1.0" }

  let(:ohai_data) do
    {
      fqdn: fqdn,
      hostname: hostname,
      machinename: machinename,
      platform: platform,
      platform_version: platform_version,
    }
  end

  let(:ohai_system) do
    ohai = instance_double("Ohai::System", all_plugins: true, data: ohai_data, logger: logger)
    allow(ohai).to receive(:[]) do |k|
      ohai_data[k]
    end
    ohai
  end

  let(:node) do
    Chef::Node.new.tap do |n|
      n.name(fqdn)
      n.chef_environment("_default")
    end
  end

  let(:json_attribs) { nil }
  let(:client_opts) { {} }

  let(:stdout) { STDOUT }
  let(:stderr) { STDERR }

  let(:client) do
    Chef::Config[:event_loggers] = []
    allow(Ohai::System).to receive(:new).and_return(ohai_system)
    opts = client_opts.merge({ logger: logger })
    Chef::Client.new(json_attribs, opts).tap do |c|
      c.node = node
    end
  end

  let(:logger) { instance_double("Mixlib::Log::Child", trace: nil, debug: nil, warn: nil, info: nil, error: nil, fatal: nil) }

  before do
    stub_const("Chef::Client::STDOUT_FD", stdout)
    stub_const("Chef::Client::STDERR_FD", stderr)
    allow(client).to receive(:logger).and_return(logger)
  end
end

# Stubs a client for a client run.
# Requires a client object be defined in the scope of this included context.
# e.g.:
#   describe "some functionality" do
#     include_context "client"
#     include_context "a client run"
#     ...
#   end
shared_context "a client run" do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  let(:api_client_exists?) { false }
  let(:enable_fork)        { false }

  let(:http_data_collector)   { double("Chef::ServerAPI (data collector)") }
  let(:http_cookbook_sync)    { double("Chef::ServerAPI (cookbook sync)") }
  let(:http_node_load)        { double("Chef::ServerAPI (node)") }
  let(:http_node_save)        { double("Chef::ServerAPI (node save)") }
  let(:reporting_rest_client) { double("Chef::ServerAPI (reporting client)") }

  let(:runner)       { instance_double("Chef::Runner") }
  let(:audit_runner) { instance_double("Chef::Audit::Runner", failed?: false) }

  def stub_for_register
    # --Client.register
    #   Make sure Client#register thinks the client key doesn't
    #   exist, so it tries to register and create one.
    allow(File).to receive(:exists?).and_call_original
    expect(File).to receive(:exists?)
      .with(Chef::Config[:client_key])
      .exactly(:once)
      .and_return(api_client_exists?)

    unless api_client_exists?
      #   Client.register will register with the validation client name.
      expect_any_instance_of(Chef::ApiClient::Registration).to receive(:run)
    end
  end

  def stub_for_data_collector_init
    expect(Chef::ServerAPI).to receive(:new)
      .with(Chef::Config[:data_collector][:server_url], validate_utf8: false)
      .exactly(:once)
      .and_return(http_data_collector)
  end

  def stub_for_node_load
    #   Client.register will then turn around create another
    #   Chef::ServerAPI object, this time with the client key it got from the
    #   previous step.
    expect(Chef::ServerAPI).to receive(:new)
      .with(Chef::Config[:chef_server_url], client_name: fqdn,
                                           signing_key_filename: Chef::Config[:client_key])
      .exactly(:once)
      .and_return(http_node_load)

    # --Client#build_node
    #   looks up the node, which we will return, then later saves it.
    expect(Chef::Node).to receive(:find_or_create).with(fqdn).and_return(node)

    # --ResourceReporter#node_load_completed
    #   gets a run id from the server for storing resource history
    #   (has its own tests, so stubbing it here.)
    expect_any_instance_of(Chef::ResourceReporter).to receive(:node_load_completed)
  end

  def stub_rest_clean
    allow(client).to receive(:rest_clean).and_return(reporting_rest_client)
  end

  def stub_for_sync_cookbooks
    # --Client#setup_run_context
    # ---Client#sync_cookbooks -- downloads the list of cookbooks to sync
    #
    expect_any_instance_of(Chef::CookbookSynchronizer).to receive(:sync_cookbooks)
    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_url], version_class: Chef::CookbookManifestVersions).and_return(http_cookbook_sync)
    expect(http_cookbook_sync).to receive(:post)
      .with("environments/_default/cookbook_versions", { run_list: [] })
      .and_return({})
  end

  def stub_for_required_recipe
    response = Net::HTTPNotFound.new("1.1", "404", "Not Found")
    exception = Net::HTTPServerException.new('404 "Not Found"', response)
    expect(http_node_load).to receive(:get).with("required_recipe").and_raise(exception)
  end

  def stub_for_converge
    # define me
  end

  def stub_for_audit
    # define me
  end

  def stub_for_node_save
    # define me
  end

  def stub_for_run
    # define me
  end

  before do
    Chef::Config[:client_fork] = enable_fork
    Chef::Config[:cache_path] = windows? ? 'C:\chef' : "/var/chef"
    Chef::Config[:why_run] = false
    Chef::Config[:audit_mode] = :enabled
    Chef::Config[:chef_guid] = "default-guid"

    stub_rest_clean
    stub_for_register
    stub_for_data_collector_init
    stub_for_node_load
    stub_for_sync_cookbooks
    stub_for_required_recipe
    stub_for_converge
    stub_for_audit
    stub_for_node_save

    expect_any_instance_of(Chef::RunLock).to receive(:acquire)
    expect_any_instance_of(Chef::RunLock).to receive(:save_pid)
    expect_any_instance_of(Chef::RunLock).to receive(:release)

    # Post conditions: check that node has been filled in correctly
    expect(client).to receive(:run_started)

    stub_for_run
  end
end

shared_context "converge completed" do
  def stub_for_converge
    # --Client#converge
    expect(Chef::Runner).to receive(:new).and_return(runner)
    expect(runner).to receive(:converge).and_return(true)
  end

  def stub_for_node_save
    allow(node).to receive(:data_for_save).and_return(node.for_json)

    # --Client#save_updated_node
    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_url], client_name: fqdn,
                                                                                  signing_key_filename: Chef::Config[:client_key], validate_utf8: false).and_return(http_node_save)
    expect(http_node_save).to receive(:put).with("nodes/#{fqdn}", node.for_json).and_return(true)
  end
end

shared_context "converge failed" do
  let(:converge_error) do
    err = Chef::Exceptions::UnsupportedAction.new("Action unsupported")
    err.set_backtrace([ "/path/recipe.rb:15", "/path/recipe.rb:12" ])
    err
  end

  def stub_for_converge
    expect(Chef::Runner).to receive(:new).and_return(runner)
    expect(runner).to receive(:converge).and_raise(converge_error)
  end

  def stub_for_node_save
    expect(client).to_not receive(:save_updated_node)
  end
end

shared_context "audit phase completed" do
  def stub_for_audit
    # -- Client#run_audits
    expect(Chef::Audit::Runner).to receive(:new).and_return(audit_runner)
    expect(audit_runner).to receive(:run).and_return(true)
    expect(client.events).to receive(:audit_phase_complete)
  end
end

shared_context "audit phase failed with error" do
  let(:audit_error) do
    err = RuntimeError.new("Unexpected audit error")
    err.set_backtrace([ "/path/recipe.rb:57", "/path/recipe.rb:55" ])
    err
  end

  def stub_for_audit
    expect(Chef::Audit::Runner).to receive(:new).and_return(audit_runner)
    expect(Chef::Audit::Logger).to receive(:read_buffer).and_return("Audit mode output!")
    expect(audit_runner).to receive(:run).and_raise(audit_error)
    expect(client.events).to receive(:audit_phase_failed).with(audit_error, "Audit mode output!")
  end
end

shared_context "audit phase completed with failed controls" do
  let(:audit_runner) do
    instance_double("Chef::Audit::Runner", failed?: true,
                                           num_failed: 1, num_total: 3) end

  let(:audit_error) do
    err = Chef::Exceptions::AuditsFailed.new(audit_runner.num_failed, audit_runner.num_total)
    err.set_backtrace([ "/path/recipe.rb:108", "/path/recipe.rb:103" ])
    err
  end

  def stub_for_audit
    expect(Chef::Audit::Runner).to receive(:new).and_return(audit_runner)
    expect(Chef::Audit::Logger).to receive(:read_buffer).and_return("Audit mode output!")
    expect(audit_runner).to receive(:run)
    expect(Chef::Exceptions::AuditsFailed).to receive(:new).with(
      audit_runner.num_failed, audit_runner.num_total
    ).and_return(audit_error)
    expect(client.events).to receive(:audit_phase_failed).with(audit_error, "Audit mode output!")
  end
end

shared_context "run completed" do
  def stub_for_run
    expect(client).to receive(:run_completed_successfully)

    # --ResourceReporter#run_completed
    #   updates the server with the resource history
    #   (has its own tests, so stubbing it here.)
    expect_any_instance_of(Chef::ResourceReporter).to receive(:run_completed)
    # --AuditReporter#run_completed
    #   posts the audit data to server.
    #   (has its own tests, so stubbing it here.)
    expect_any_instance_of(Chef::Audit::AuditReporter).to receive(:run_completed)
  end
end

shared_context "run failed" do
  def stub_for_run
    expect(client).to receive(:run_failed)

    # --ResourceReporter#run_completed
    #   updates the server with the resource history
    #   (has its own tests, so stubbing it here.)
    expect_any_instance_of(Chef::ResourceReporter).to receive(:run_failed)
    # --AuditReporter#run_completed
    #   posts the audit data to server.
    #   (has its own tests, so stubbing it here.)
    expect_any_instance_of(Chef::Audit::AuditReporter).to receive(:run_failed)
  end

  before do
    expect(Chef::Application).to receive(:debug_stacktrace).with an_instance_of(Chef::Exceptions::RunFailedWrappingError)
  end
end
