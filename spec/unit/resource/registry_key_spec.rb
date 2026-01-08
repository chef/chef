#
# Author:: Lamont Granquist (<lamont@chef.io>)
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

describe Chef::Resource::RegistryKey, "initialize" do
  let(:resource) { Chef::Resource::RegistryKey.new("HKCU\\Software\\Raxicoricofallapatorius") }

  it "sets the resource_name to :registry_key" do
    expect(resource.resource_name).to eql(:registry_key)
  end

  it "the key property is the name_property" do
    expect(resource.key).to eql("HKCU\\Software\\Raxicoricofallapatorius")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :create_if_missing, :delete, :delete_key actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :create_if_missing }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :delete_key }.not_to raise_error
  end

  it "defaults recursive to false" do
    expect(resource.recursive).to eql(false)
  end

  it "defaults architecture to :machine" do
    expect(resource.architecture).to eql(:machine)
  end

  it "sets action to :create" do
    expect(resource.action).to eql([:create])
  end

  %w{create create_if_missing delete delete_key}.each do |action|
    it "allows action #{action}" do
      expect(resource.allowed_actions.detect { |a| a == action.to_sym }).to eql(action.to_sym)
    end
  end
end

describe Chef::Resource::RegistryKey, "key" do
  let(:resource) { Chef::Resource::RegistryKey.new("HKCU\\Software\\Raxicoricofallapatorius") }

  it "allows a string" do
    resource.key "HKCU\\Software\\Poosh"
    expect(resource.key).to eql("HKCU\\Software\\Poosh")
  end

  it "does not allow an integer" do
    expect { resource.send(:key, 100) }.to raise_error(ArgumentError)
  end

  it "does not allow a hash" do
    expect { resource.send(:key, { sonic: "screwdriver" }) }.to raise_error(ArgumentError)
  end
end

describe Chef::Resource::RegistryKey, "values" do
  let(:resource) { Chef::Resource::RegistryKey.new("HKCU\\Software\\Raxicoricofallapatorius") }

  it "allows a single proper hash of registry values" do
    resource.values( { name: "poosh", type: :string, data: "carmen" } )
    expect(resource.values).to eql([ { name: "poosh", type: :string, data: "carmen" } ])
  end

  it "allows an array of proper hashes of registry values" do
    resource.values [ { name: "poosh", type: :string, data: "carmen" } ]
    expect(resource.values).to eql([ { name: "poosh", type: :string, data: "carmen" } ])
  end

  it "returns checksummed data if the type is unsafe" do
    resource.values( { name: "poosh", type: :binary, data: 255.chr * 1 })
    expect(resource.values).to eql([ { name: "poosh", type: :binary, data: "a8100ae6aa1940d0b663bb31cd466142ebbdbd5187131b92d93818987832eb89" } ])
  end

  it "raises an exception if the name field is missing" do
    expect { resource.values [ { type: :string, data: "carmen" } ] }.to raise_error(ArgumentError)
  end

  it "raises an exception if extra fields are present" do
    expect { resource.values [ { name: "poosh", type: :string, data: "carmen", screwdriver: "sonic" } ] }.to raise_error(ArgumentError)
  end

  it "does not allow a string" do
    expect { resource.send(:values, "souffle") }.to raise_error(ArgumentError)
  end

  it "does not allow an integer" do
    expect { resource.send(:values, 100) }.to raise_error(ArgumentError)
  end

  it "raises an exception if type of name is not string" do
    expect { resource.values([ { name: 123, type: :string, data: "carmen" } ]) }.to raise_error(ArgumentError)
  end

  it "does not raise an exception if type of name is string" do
    expect { resource.values([ { name: "123", type: :string, data: "carmen" } ]) }.to_not raise_error
  end

  context "type key not given" do
    it "does not raise an exception" do
      expect { resource.values([ { name: "123", data: "carmen" } ]) }.to_not raise_error
    end
  end

  context "type key given" do
    it "raises an exception if type of type is not symbol" do
      expect { resource.values([ { name: "123", type: "string", data: "carmen" } ]) }.to raise_error(ArgumentError)
    end

    it "does not raise an exception if type of type is symbol" do
      expect { resource.values([ { name: "123", type: :string, data: "carmen" } ]) }.to_not raise_error
    end
  end

  it "does not raise an exception if keys are in string format" do
    expect { resource.values([ { "name" => "123", "type" => :string, "data" => "carmen" } ]) }.to_not raise_error
  end
end

describe Chef::Resource::RegistryKey, "recursive" do
  let(:resource) { Chef::Resource::RegistryKey.new("HKCU\\Software\\Raxicoricofallapatorius") }

  it "allows a boolean" do
    resource.recursive(true)
    expect(resource.recursive).to eql(true)
  end

  it "does not allow a hash" do
    expect { resource.recursive({ sonic: :screwdriver }) }.to raise_error(ArgumentError)
  end

  it "does not allow an array" do
    expect { resource.recursive(%i{nose chin}) }.to raise_error(ArgumentError)
  end

  it "does not allow a string" do
    expect { resource.recursive("souffle") }.to raise_error(ArgumentError)
  end

  it "does not allow an integer" do
    expect { resource.recursive(100) }.to raise_error(ArgumentError)
  end
end

describe Chef::Resource::RegistryKey, "architecture" do
  let(:resource) { Chef::Resource::RegistryKey.new("HKCU\\Software\\Raxicoricofallapatorius") }

  %i{i386 x86_64 machine}.each do |arch|
    it "allows #{arch} as a symbol" do
      resource.architecture(arch)
      expect(resource.architecture).to eql(arch)
    end
  end

  it "does not allow other symbols" do
    expect { resource.architecture(:nope) }.to raise_error(ArgumentError)
  end

  it "does not allow a hash" do
    expect { resource.architecture({ sonic: :screwdriver }) }.to raise_error(ArgumentError)
  end

  it "does not allow an array" do
    expect { resource.architecture(%i{nose chin}) }.to raise_error(ArgumentError)
  end

  it "does not allow a string" do
    expect { resource.architecture("souffle") }.to raise_error(ArgumentError)
  end

  it "does not allow an integer" do
    expect { resource.architecture(100) }.to raise_error(ArgumentError)
  end
end

describe Chef::Resource::RegistryKey, ":unscrubbed_values" do
  let(:resource) { Chef::Resource::RegistryKey.new("HKCU\\Software\\Raxicoricofallapatorius") }

  it "returns unsafe data as-is" do
    key_values = [ { name: "poosh", type: :binary, data: 255.chr * 1 } ]
    resource.values(key_values)
    expect(resource.unscrubbed_values).to eql(key_values)
  end
end

describe Chef::Resource::RegistryKey, "state" do
  let(:resource) { Chef::Resource::RegistryKey.new("HKCU\\Software\\Raxicoricofallapatorius") }

  it "returns scrubbed values" do
    resource.values([ { name: "poosh", type: :binary, data: 255.chr * 1 } ])
    expect(resource.state_for_resource_reporter[:values]).to eql( [{ name: "poosh", type: :binary, data: "a8100ae6aa1940d0b663bb31cd466142ebbdbd5187131b92d93818987832eb89" }] )
  end
end
