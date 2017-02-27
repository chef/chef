#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
require "support/shared/unit/resource/static_provider_resolution"

describe Chef::Resource::ChefGem, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::ChefGem,
    provider: Chef::Provider::Package::Rubygems,
    name: :chef_gem,
    action: :install
  )

end

describe Chef::Resource::ChefGem, "gem_binary" do
  let(:resource) { Chef::Resource::ChefGem.new("foo") }

  it "should raise an exception when gem_binary is set" do
    expect { resource.gem_binary("/lol/cats/gem") }.to raise_error(ArgumentError)
  end

  it "should set the gem_binary based on computing it from RbConfig" do
    expect(resource.gem_binary).to eql("#{RbConfig::CONFIG['bindir']}/gem")
  end

  it "should set the gem_binary based on computing it from RbConfig" do
    expect(resource.compile_time).to be false
  end

  context "when building the resource" do
    let(:node) do
      Chef::Node.new
    end

    let(:run_context) do
      Chef::RunContext.new(node, {}, nil)
    end

    let(:recipe) do
      Chef::Recipe.new("hjk", "test", run_context)
    end

    let(:resource) do
      Chef::Resource::ChefGem.new("foo", run_context)
    end

    before do
      expect(Chef::Resource::ChefGem).to receive(:new).and_return(resource)
    end

    it "by default does not install at compile-time" do
      expect(resource).not_to receive(:run_action).with(:install)
      recipe.chef_gem "foo"
    end

    it "compile_time true installs at compile-time" do
      expect(resource).to receive(:run_action).with(:install)
      recipe.chef_gem "foo" do
        compile_time true
      end
    end

    it "compile_time false does not install at compile-time" do
      expect(resource).not_to receive(:run_action).with(:install)
      recipe.chef_gem "foo" do
        compile_time false
      end
    end

    describe "when Chef::Config[:chef_gem_compile_time] is explicitly true" do
      before do
        Chef::Config[:chef_gem_compile_time] = true
        expect(Chef::Log).not_to receive(:deprecation)
      end

      it "by default installs at compile-time" do
        expect(resource).to receive(:run_action).with(:install)
        recipe.chef_gem "foo"
      end

      it "compile_time true installs at compile-time" do
        expect(resource).to receive(:run_action).with(:install)
        recipe.chef_gem "foo" do
          compile_time true
        end
      end

      it "compile_time false does not install at compile-time" do
        expect(resource).not_to receive(:run_action).with(:install)
        recipe.chef_gem "foo" do
          compile_time false
        end
      end
    end

    describe "when Chef::Config[:chef_gem_compile_time] is explicitly false" do

      before do
        Chef::Config[:chef_gem_compile_time] = false
        expect(Chef::Log).not_to receive(:deprecation)
      end

      it "by default does not install at compile-time" do
        expect(resource).not_to receive(:run_action).with(:install)
        recipe.chef_gem "foo"
      end

      it "compile_time true installs at compile-time" do
        expect(resource).to receive(:run_action).with(:install)
        recipe.chef_gem "foo" do
          compile_time true
        end
      end

      it "compile_time false does not install at compile-time" do
        expect(resource).not_to receive(:run_action).with(:install)
        recipe.chef_gem "foo" do
          compile_time false
        end
      end
    end
  end
end
