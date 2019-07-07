#
# Copyright:: 2019, Chef Software, Inc.
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

describe Chef::Resource::RunitService do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::RunitService.new("fakey_fakerton", run_context) }

  it "sv_bin defaults to /sbin/sv on non-debian platforms by default" do
    expect(resource.sv_bin).to eql("/sbin/sv")
  end

  it "sv_dir defaults to /etc/sv by default" do
    expect(resource.sv_dir).to eql("/etc/sv")
  end

  it "service_dir defaults to /etc/service by default" do
    expect(resource.service_dir).to eql("/etc/service")
  end

  it "lsb_init_dir defaults to /etc/init.d by default" do
    expect(resource.lsb_init_dir).to eql("/etc/init.d")
  end

  %w{check_script_template_name finish_script_template_name run_template_name log_template_name}.each do |prop|
    it "the #{prop} property is the service_name property value by default" do
      expect(resource.send(prop)).to eql("fakey_fakerton")
    end
  end

  it "the log_dir property is /var/log/fakey_fakerton by default" do
    expect(resource.log_dir).to eql("/var/log/fakey_fakerton")
  end

  it "the log_flags property is -tt by default" do
    expect(resource.log_flags).to eql("-tt")
  end

  it "the status_command property is /etc/sv status fakey_fakerton by default" do
    expect(resource.status_command).to eql("/sbin/sv status fakey_fakerton")
  end

  it "the options property gets a legacy value for compatibility with the definition if env is not set" do
    expect(resource.options).to eql({ env_dir: "/etc/sv/fakey_fakerton/env" })
  end

  it "the options control_template_names is an empty hash if the control property is not set" do
    expect(resource.control_template_names).to eql({})
  end

  it "the options control_template_names sets a default value if the control property is set" do
    resource.control %w{foo bar}
    expect(resource.control_template_names).to eql({ "bar" => "fakey_fakerton", "foo" => "fakey_fakerton" })
  end

  it "the options property coerces in the default value to whatever is provided" do
    resource.options foo: "bar"
    expect(resource.options).to eql({ env_dir: "/etc/sv/fakey_fakerton/env", foo: "bar" })
  end

  it "the status_command default changes if sv_bin property is set" do
    resource.sv_bin "/bin/something/else"
    expect(resource.status_command).to eql("/bin/something/else status fakey_fakerton")
  end

  it "the service_name property is the name_property" do
    expect(resource.service_name).to eql("fakey_fakerton")
  end

  it "the default_action is :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports all valid service actions" do
    %w{nothing start stop enable disable restart reload status once hup cont term kill up down usr1 usr2 create reload_log}.each do |act|
      expect { resource.action act.to_sym }.not_to raise_error
    end
  end
end
