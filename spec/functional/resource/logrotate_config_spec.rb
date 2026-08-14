#
# Copyright:: 2026, Tim Smith
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "tmpdir"

describe Chef::Resource::LogrotateConfig, :linux_only do
  include Chef::Mixin::ShellOut
  include ChefUtils::DSL::Which

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::LogrotateConfig.new("chef_functional_test", run_context) }

  before do
    skip "logrotate is not installed" unless which("logrotate")
  end

  # logrotate -d exits 0 even for an unknown option -- it prints "error: ... unknown option
  # 'foo' -- ignoring line" and carries on. Asserting on the absence of error output rather
  # than on the exit code is therefore the only way to catch a directive logrotate rejected.
  # State-file errors are filtered out because the state file intentionally does not exist.
  def logrotate_errors_for(content)
    Dir.mktmpdir("chef-logrotate") do |dir|
      log_dir = ::File.join(dir, "logs")
      ::FileUtils.mkdir_p(log_dir)
      ::File.write(::File.join(log_dir, "app.log"), "some log data\n")

      config = ::File.join(dir, "test.conf")
      ::File.write(config, content.gsub("LOGDIR", log_dir))

      result = shell_out("logrotate -d --state #{::File.join(dir, "state")} #{config}")
      (result.stdout + result.stderr).lines.grep(/^error:/).reject { |l| l.include?("state file") }
    end
  end

  describe "the generated configuration" do
    it "is accepted by logrotate with no errors" do
      resource.path("LOGDIR/*.log")
      resource.frequency("daily")
      resource.rotate(14)
      resource.compress(true)
      resource.delaycompress(true)
      resource.missingok(true)
      resource.notifempty(true)
      resource.sharedscripts(true)
      resource.create("0640 root adm")
      resource.postrotate("/bin/true")

      expect(logrotate_errors_for(resource.config_content)).to be_empty
    end

    it "is accepted by logrotate when only the escape hatch is used" do
      resource.path("LOGDIR/*.log")
      resource.directives(["daily", "rotate 3", "dateext"])

      expect(logrotate_errors_for(resource.config_content)).to be_empty
    end

    # Guards the two assertions above: without this, they would still pass if
    # logrotate_errors_for silently returned nothing for every input. The exact
    # wording varies between logrotate versions and with the shape of the bad
    # input, so this asserts only that something was reported.
    it "reports an error when the escape hatch contains an unknown directive" do
      resource.path("LOGDIR/*.log")
      resource.directives(["notarealdirective"])

      expect(logrotate_errors_for(resource.config_content)).not_to be_empty
    end
  end

  describe "actions", :requires_root do
    let(:config_file) { "/etc/logrotate.d/chef_functional_test" }

    after { ::File.delete(config_file) if ::File.exist?(config_file) }

    it "creates the configuration file with the configured mode" do
      resource.path("/var/log/chef_functional_test/*.log")
      resource.frequency("weekly")
      resource.run_action(:create)

      expect(::File.exist?(config_file)).to be true
      expect(::File.read(config_file)).to include("  weekly\n")
      expect(::File.stat(config_file).mode & 0o777).to eq(0o644)
    end

    it "deletes the configuration file" do
      resource.run_action(:create)
      expect(::File.exist?(config_file)).to be true

      resource.run_action(:delete)
      expect(::File.exist?(config_file)).to be false
    end
  end
end
