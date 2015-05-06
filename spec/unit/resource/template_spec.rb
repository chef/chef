#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'spec_helper'

describe Chef::Resource::Template do

  before(:each) do
    @resource = Chef::Resource::Template.new("fakey_fakerton")
  end

  describe "initialize" do
    it "should create a new Chef::Resource::Template" do
      expect(@resource).to be_a_kind_of(Chef::Resource)
      expect(@resource).to be_a_kind_of(Chef::Resource::File)
      expect(@resource).to be_a_kind_of(Chef::Resource::Template)
    end
  end

  describe "source" do
    it "should accept a string for the template source" do
      @resource.source "something"
      expect(@resource.source).to eql("something")
    end

    it "should have a default based on the param name with .erb appended" do
      expect(@resource.source).to eql("fakey_fakerton.erb")
    end

    it "should use only the basename of the file as the default" do
      r = Chef::Resource::Template.new("/tmp/obit/fakey_fakerton")
      expect(r.source).to eql("fakey_fakerton.erb")
    end
  end

  describe "variables" do
    it "should accept a hash for the variable list" do
      @resource.variables({ :reluctance => :awkward })
      expect(@resource.variables).to eq({ :reluctance => :awkward })
    end
  end

  describe "cookbook" do
    it "should accept a string for the cookbook name" do
      @resource.cookbook("foo")
      expect(@resource.cookbook).to eq("foo")
    end

    it "should default to nil" do
      expect(@resource.cookbook).to eq(nil)
    end
  end

  describe "local" do
    it "should accept a boolean for whether a template is local or remote" do
      @resource.local(true)
      expect(@resource.local).to eq(true)
    end

    it "should default to false" do
      expect(@resource.local).to eq(false)
    end
  end

  describe "when it has a path, owner, group, mode, and checksum" do
    before do
      @resource.path("/tmp/foo.txt")
      @resource.owner("root")
      @resource.group("wheel")
      @resource.mode("0644")
      @resource.checksum("1" * 64)
    end

    context "on unix", :unix_only do
      it "describes its state" do
        state = @resource.state
        expect(state[:owner]).to eq("root")
        expect(state[:group]).to eq("wheel")
        expect(state[:mode]).to eq("0644")
        expect(state[:checksum]).to eq("1" * 64)
      end
    end

    context "on windows", :windows_only do
      # according to Chef::Resource::File, windows state attributes are rights + deny_rights
      pending "it describes its state"
    end

    it "returns the file path as its identity" do
      expect(@resource.identity).to eq("/tmp/foo.txt")
    end
  end

  describe "defining helper methods" do

    module ExampleHelpers
      def static_example
        "static_example"
      end
    end

    it "collects helper method bodies as blocks" do
      @resource.helper(:example_1) { "example_1" }
      @resource.helper(:example_2) { "example_2" }
      expect(@resource.inline_helper_blocks[:example_1].call).to eq("example_1")
      expect(@resource.inline_helper_blocks[:example_2].call).to eq("example_2")
    end

    it "compiles helper methods into a module" do
      @resource.helper(:example_1) { "example_1" }
      @resource.helper(:example_2) { "example_2" }
      modules = @resource.helper_modules
      expect(modules.size).to eq(1)
      o = Object.new
      modules.each {|m| o.extend(m)}
      expect(o.example_1).to eq("example_1")
      expect(o.example_2).to eq("example_2")
    end

    it "compiles helper methods with arguments into a module" do
      @resource.helper(:shout) { |quiet| quiet.upcase }
      modules = @resource.helper_modules
      o = Object.new
      modules.each {|m| o.extend(m)}
      expect(o.shout("shout")).to eq("SHOUT")
    end

    it "raises an error when attempting to define a helper method without a method body" do
      expect { @resource.helper(:example) }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "raises an error when attempting to define a helper method with a non-Symbod method name" do
      expect { @resource.helper("example") { "fail" } }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "collects helper module bodies as blocks" do
      @resource.helpers do
        def example_1
          "example_1"
        end
      end
      module_body = @resource.inline_helper_modules.first
      expect(module_body).to be_a(Proc)
    end

    it "compiles helper module bodies into modules" do
      @resource.helpers do
        def example_1
          "example_1"
        end
      end
      modules = @resource.helper_modules
      expect(modules.size).to eq(1)
      o = Object.new
      modules.each {|m| o.extend(m)}
      expect(o.example_1).to eq("example_1")
    end

    it "raises an error when no block or module name is given for helpers definition" do
      expect { @resource.helpers() }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "raises an error when a non-module is given for helpers definition" do
      expect { @resource.helpers("NotAModule") }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "raises an error when a module name and block are both given for helpers definition" do
      expect { @resource.helpers(ExampleHelpers) { module_code } }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "collects helper modules", :focus do
      @resource.helpers(ExampleHelpers)
      expect(@resource.helper_modules).to include(ExampleHelpers)
    end

    it "combines all helpers into a set of compiled modules" do
      @resource.helpers(ExampleHelpers)
      @resource.helpers do
        def inline_module
          "inline_module"
        end
      end
      @resource.helper(:inline_method) { "inline_method" }
      expect(@resource.helper_modules.size).to eq(3)

      o = Object.new
      @resource.helper_modules.each {|m| o.extend(m)}
      expect(o.static_example).to eq("static_example")
      expect(o.inline_module).to eq("inline_module")
      expect(o.inline_method).to eq("inline_method")
    end


  end

end
