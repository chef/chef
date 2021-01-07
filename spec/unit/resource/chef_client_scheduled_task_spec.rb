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

describe Chef::Resource::ChefClientScheduledTask do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientScheduledTask.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:add) }

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "coerces splay to an Integer" do
    resource.splay "10"
    expect(resource.splay).to eql(10)
  end

  it "raises an error if splay is not a positive number" do
    expect { resource.splay("-10") }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "coerces frequency_modifier to an Integer" do
    resource.frequency_modifier "10"
    expect(resource.frequency_modifier).to eql(10)
  end

  it "expects default frequency modifier to be 30 when frequency is set to 'minute'" do
    resource.frequency "minute"
    expect(resource.frequency_modifier).to eql(30)
  end

  it "expects default frequency modifier to be 1 when frequency is set to 'daily'" do
    resource.frequency "daily"
    expect(resource.frequency_modifier).to eql(1)
  end

  it "validates the start_time property input" do
    expect { resource.start_time("8:00 am") }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.start_time("8:00") }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.start_time("08:00") }.not_to raise_error
  end

  it "validates the start_date property input" do
    expect { resource.start_date("2/1/20") }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.start_date("02/01/20") }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.start_date("02/01/2020") }.not_to raise_error
  end

  it "raises an error if frequency_modifier is not a positive number" do
    expect { resource.frequency_modifier("-10") }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "builds a default value for chef_binary_path dist values" do
    expect(resource.chef_binary_path).to eql("C:/opscode/chef/bin/chef-client")
  end

  it "supports :add and :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  describe "#client_cmd" do
    it "creates a valid command if using all default properties" do
      expect(provider.client_cmd).to eql("C:/opscode/chef/bin/chef-client -L /etc/chef/log/client.log -c /etc/chef/client.rb") | eql("C:/opscode/chef/bin/chef-client -L C:\\chef/log/client.log -c C:\\chef/client.rb")
    end

    it "uses daemon_options if set" do
      resource.daemon_options ["--foo 1", "--bar 2"]
      expect(provider.client_cmd).to eql("C:/opscode/chef/bin/chef-client -L /etc/chef/log/client.log -c /etc/chef/client.rb --foo 1 --bar 2") | eql("C:/opscode/chef/bin/chef-client -L C:\\chef/log/client.log -c C:\\chef/client.rb --foo 1 --bar 2")
    end

    it "uses custom config dir if set" do
      resource.config_directory "C:/foo/bar"
      expect(provider.client_cmd).to eql("C:/opscode/chef/bin/chef-client -L C:/foo/bar/log/client.log -c C:/foo/bar/client.rb")
    end

    it "uses custom log files / paths if set" do
      resource.log_file_name "my-client.log"
      resource.log_directory "C:/foo/bar"
      expect(provider.client_cmd).to eql("C:/opscode/chef/bin/chef-client -L C:/foo/bar/my-client.log -c /etc/chef/client.rb") | eql("C:/opscode/chef/bin/chef-client -L C:/foo/bar/my-client.log -c C:\\chef/client.rb")
    end

    it "uses custom chef-client binary if set" do
      resource.chef_binary_path "C:/foo/bar/chef-client"
      expect(provider.client_cmd).to eql("C:/foo/bar/chef-client -L /etc/chef/log/client.log -c /etc/chef/client.rb") | eql("C:/foo/bar/chef-client -L C:\\chef/log/client.log -c C:\\chef/client.rb")
    end

    it "sets the license acceptance flag if set" do
      resource.accept_chef_license true
      expect(provider.client_cmd).to eql("C:/opscode/chef/bin/chef-client -L /etc/chef/log/client.log -c /etc/chef/client.rb --chef-license accept") | eql("C:/opscode/chef/bin/chef-client -L C:\\chef/log/client.log -c C:\\chef/client.rb --chef-license accept")
    end
  end
end
