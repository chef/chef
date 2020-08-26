#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Resource::ChefClientLaunchd do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientLaunchd.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:enable) }

  it "sets the default action as :enable" do
    expect(resource.action).to eql([:enable])
  end

  it "builds a default value for chef_binary_path dist values" do
    expect(resource.chef_binary_path).to eql("/opt/chef/bin/chef-client")
  end

  it "supports :enable and :disable actions" do
    expect { resource.action :enable }.not_to raise_error
    expect { resource.action :disable }.not_to raise_error
  end

  it "raises an error if interval is not a positive number" do
    expect { resource.interval("-10") }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "coerces interval to an Integer" do
    resource.interval "10"
    expect(resource.interval).to eql(10)
  end

  it "raises an error if nice is less than -20" do
    expect { resource.nice(-21) }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "raises an error if nice is greater than 19" do
    expect { resource.nice(20) }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "coerces nice to an Integer" do
    resource.nice "10"
    expect(resource.nice).to eql(10)
  end

  describe "#all_daemon_options" do
    it "returns log and config flags if by default" do
      expect(provider.all_daemon_options).to eql(
        ["-L", "/Library/Logs/Chef/client.log", "-c", "/etc/chef/client.rb"]
      )
    end

    it "appends to any passed daemon options" do
      resource.daemon_options %w{foo bar}
      expect(provider.all_daemon_options).to eql(
        ["foo", "bar", "-L", "/Library/Logs/Chef/client.log", "-c", "/etc/chef/client.rb"]
      )
    end

    it "adds license acceptance flags if the property is set" do
      resource.accept_chef_license true
      expect(provider.all_daemon_options).to eql(
        ["-L", "/Library/Logs/Chef/client.log", "-c", "/etc/chef/client.rb", "--chef-license", "accept"]
      )
    end

    it "uses custom config dir if set" do
      resource.config_directory "/etc/some_other_dir"
      expect(provider.all_daemon_options).to eql(
        ["-L", "/Library/Logs/Chef/client.log", "-c", "/etc/some_other_dir/client.rb"]
      )
    end

    it "uses custom log files / paths if set" do
      resource.log_file_name "my-client.log"
      resource.log_directory "/var/log/my-chef/"
      expect(provider.all_daemon_options).to eql(
        ["-L", "/var/log/my-chef/my-client.log", "-c", "/etc/chef/client.rb"]
      )
    end
  end
end
