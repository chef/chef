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
      @resource.should be_a_kind_of(Chef::Resource)
      @resource.should be_a_kind_of(Chef::Resource::File)
      @resource.should be_a_kind_of(Chef::Resource::Template)
    end
  end

  describe "source" do
    it "should accept a string for the template source" do
      @resource.source "something"
      @resource.source.should eql("something")
    end

    it "should have a default based on the param name with .erb appended" do
      @resource.source.should eql("fakey_fakerton.erb")
    end

    it "should use only the basename of the file as the default" do
      r = Chef::Resource::Template.new("/tmp/obit/fakey_fakerton")
      r.source.should eql("fakey_fakerton.erb")
    end
  end

  describe "variables" do
    it "should accept a hash for the variable list" do
      @resource.variables({ :reluctance => :awkward })
      @resource.variables.should == { :reluctance => :awkward }
    end
  end

  describe "cookbook" do
    it "should accept a string for the cookbook name" do
      @resource.cookbook("foo")
      @resource.cookbook.should == "foo"
    end

    it "should default to nil" do
      @resource.cookbook.should == nil
    end
  end

  describe "local" do
    it "should accept a boolean for whether a template is local or remote" do
      @resource.local(true)
      @resource.local.should == true
    end

    it "should default to false" do
      @resource.local.should == false
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
        state[:owner].should == "root"
        state[:group].should == "wheel"
        state[:mode].should == "0644"
        state[:checksum].should == "1" * 64
      end
    end

    context "on windows", :windows_only do
      # according to Chef::Resource::File, windows state attributes are rights + deny_rights
      pending "it describes its state"
    end

    it "returns the file path as its identity" do
      @resource.identity.should == "/tmp/foo.txt"
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
      @resource.inline_helper_blocks[:example_1].call.should == "example_1"
      @resource.inline_helper_blocks[:example_2].call.should == "example_2"
    end

    it "compiles helper methods into a module" do
      @resource.helper(:example_1) { "example_1" }
      @resource.helper(:example_2) { "example_2" }
      modules = @resource.helper_modules
      modules.should have(1).module
      o = Object.new
      modules.each {|m| o.extend(m)}
      o.example_1.should == "example_1"
      o.example_2.should == "example_2"
    end

    it "compiles helper methods with arguments into a module" do
      @resource.helper(:shout) { |quiet| quiet.upcase }
      modules = @resource.helper_modules
      o = Object.new
      modules.each {|m| o.extend(m)}
      o.shout("shout").should == "SHOUT"
    end

    it "raises an error when attempting to define a helper method without a method body" do
      lambda { @resource.helper(:example) }.should raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "raises an error when attempting to define a helper method with a non-Symbod method name" do
      lambda { @resource.helper("example") { "fail" } }.should raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "collects helper module bodies as blocks" do
      @resource.helpers do
        def example_1
          "example_1"
        end
      end
      module_body = @resource.inline_helper_modules.first
      module_body.should be_a(Proc)
    end

    it "compiles helper module bodies into modules" do
      @resource.helpers do
        def example_1
          "example_1"
        end
      end
      modules = @resource.helper_modules
      modules.should have(1).module
      o = Object.new
      modules.each {|m| o.extend(m)}
      o.example_1.should == "example_1"
    end

    it "raises an error when no block or module name is given for helpers definition" do
      lambda { @resource.helpers() }.should raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "raises an error when a non-module is given for helpers definition" do
      lambda { @resource.helpers("NotAModule") }.should raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "raises an error when a module name and block are both given for helpers definition" do
      lambda { @resource.helpers(ExampleHelpers) { module_code } }.should raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "collects helper modules" do
      @resource.helpers(ExampleHelpers)
      @resource.helper_modules.should include(ExampleHelpers)
    end

    it "combines all helpers into a set of compiled modules" do
      @resource.helpers(ExampleHelpers)
      @resource.helpers do
        def inline_module
          "inline_module"
        end
      end
      @resource.helper(:inline_method) { "inline_method" }
      @resource.should have(3).helper_modules

      o = Object.new
      @resource.helper_modules.each {|m| o.extend(m)}
      o.static_example.should == "static_example"
      o.inline_module.should == "inline_module"
      o.inline_method.should == "inline_method"
    end


  end

end
