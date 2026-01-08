#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

describe Chef::Resource::WindowsService, "initialize" do
  let(:resource) { Chef::Resource::WindowsService.new("fakey_fakerton") }

  it "sets the resource_name to :windows_service" do
    expect(resource.resource_name).to eql(:windows_service)
  end

  it "the service_name property is the name_property" do
    expect(resource.service_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :nothing" do
    expect(resource.action).to eql([:nothing])
  end

  it "supports :configure, :configure_startup, :create, :delete, :disable, :enable, :mask, :reload, :restart, :start, :stop, :unmask actions" do
    expect { resource.action :configure }.not_to raise_error
    expect { resource.action :configure_startup }.not_to raise_error
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :disable }.not_to raise_error
    expect { resource.action :enable }.not_to raise_error
    expect { resource.action :mask }.not_to raise_error
    expect { resource.action :reload }.not_to raise_error
    expect { resource.action :restart }.not_to raise_error
    expect { resource.action :start }.not_to raise_error
    expect { resource.action :stop }.not_to raise_error
    expect { resource.action :unmask }.not_to raise_error
  end

  it "accepts an Integer for timeout property" do
    resource.timeout 1
    expect(resource.timeout).to eql(1)
  end

  it "defaults the timeout property to 60 (seconds)" do
    expect(resource.timeout).to eql(60)
  end

  %i{automatic manual disabled}.each do |type|
    it "supports setting startup_type property to #{type.inspect}" do
      resource.startup_type type
      expect(resource.startup_type).to eql(type)
    end
  end

  { 2 => :automatic, 3 => :manual, 4 => :disabled }.each_pair do |k, v|
    it "it coerces startup_type property #{k} to #{v.inspect}" do
      resource.startup_type k
      expect(resource.startup_type).to eql(v)
    end
  end

  %w{automatic manual disabled}.each do |type|
    it "it coerces startup_type property #{type} to :#{type}" do
      resource.startup_type type
      expect(resource.startup_type).to eql(type.to_sym)
    end
  end

  %i{automatic manual disabled}.each do |type|
    it "supports setting startup_type property to #{type.inspect}" do
      resource.startup_type type
      expect(resource.startup_type).to eql(type)
    end
  end

  it "allows the action to be 'configure_startup'" do
    resource.action :configure_startup
    expect(resource.action).to eq([:configure_startup])
  end

  # Properties that are Strings
  %i{description service_name binary_path_name load_order_group dependencies
     run_as_user run_as_password display_name}.each do |prop|
       it "support setting #{prop} property with a String" do
         resource.send("#{prop}=", "some value")
         expect(resource.send(prop)).to eq("some value")
       end
     end

  # Properties that are Integers
  %i{desired_access error_control service_type}.each do |prop|
    it "support setting #{prop} property with an Integer" do
      resource.send("#{prop}=", 1)
      expect(resource.send(prop)).to eq(1)
    end
  end

  # Properties that are Booleans
  %i{delayed_start}.each do |prop|
    it "support setting #{prop}" do
      resource.send("#{prop}=", true)
      expect(resource.send(prop)).to eq(true)
    end
  end

  it "lowercases run_as_user" do
    resource.run_as_user = "JohnDoe"
    expect(resource.run_as_user).to eq("johndoe")
  end
end
