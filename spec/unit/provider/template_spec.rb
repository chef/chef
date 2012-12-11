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
require 'stringio'
require 'spec_helper'
require 'etc'
require 'ostruct'

describe Chef::Provider::Template do
  before(:each) do
    @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, @cookbook_repo) }

    @node = Chef::Node.new
    cl = Chef::CookbookLoader.new(@cookbook_repo)
    cl.load_cookbooks
    @cookbook_collection = Chef::CookbookCollection.new(cl)
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

    @rendered_file_location = Dir.tmpdir + '/openldap_stuff.conf'

    @resource = Chef::Resource::Template.new(@rendered_file_location)
    @resource.cookbook_name = 'openldap'

    @provider = Chef::Provider::Template.new(@resource, @run_context)
    @current_resource = @resource.dup
    @provider.current_resource = @current_resource
    @access_controls = mock("access controls")
    @provider.stub!(:access_controls).and_return(@access_controls)
    passwd_struct = if windows?
                      Struct::Passwd.new("root", "x", 0, 0, "/root", "/bin/bash")
                    else
                      Struct::Passwd.new("root", "x", 0, 0, "root", "/root", "/bin/bash")
                    end
    group_struct = mock("Group Ent", :name => "root", :passwd => "x", :gid => 0)
    Etc.stub!(:getpwuid).and_return(passwd_struct)
    Etc.stub!(:getgrgid).and_return(group_struct)
  end

  describe "when creating the template" do

    before do
    end

    after do
      FileUtils.rm(@rendered_file_location) if ::File.exist?(@rendered_file_location)
    end

    it "finds the template file in the coobook cache if it isn't local" do
      @provider.template_location.should == CHEF_SPEC_DATA + '/cookbooks/openldap/templates/default/openldap_stuff.conf.erb'
    end

    it "finds the template file locally if it is local" do
      @resource.local(true)
      @resource.source('/tmp/its_on_disk.erb')
      @provider.template_location.should == '/tmp/its_on_disk.erb'
    end

    it "stops executing when the local template source can't be found" do 
      @access_controls.stub!(:requires_changes?).and_return(false)
      @resource.source "invalid.erb" 
      @resource.local true
      lambda { @provider.run_action(:create) } .should raise_error Chef::Mixin::WhyRun::ResourceRequirements::Assertion::AssertionFailure
    end

    it "should use the cookbook name if defined in the template resource" do
      @resource.cookbook_name = 'apache2'
      @resource.cookbook('openldap')
      @resource.source "test.erb"
      @provider.template_location.should == CHEF_SPEC_DATA + '/cookbooks/openldap/templates/default/test.erb'
    end

    describe "when the target file does not exist" do
      it "creates the template with the rendered content" do
        @access_controls.stub!(:requires_changes?).and_return(true)
        @access_controls.should_receive(:set_all!)
        @node.normal[:slappiness] = "a warm gun"
        @provider.should_receive(:backup)
        @provider.run_action(:create)
        IO.read(@rendered_file_location).should == "slappiness is a warm gun"
        @resource.should be_updated_by_last_action
      end

      it "should set the file access control as specified in the resource" do
        @access_controls.stub!(:requires_changes?).and_return(false)
        @access_controls.should_receive(:set_all!)
        @resource.owner("adam")
        @resource.group("wheel")
        @resource.mode(00644)
        @provider.run_action(:create)
        @resource.should be_updated_by_last_action
      end

      it "creates the template with the rendered content for the create if missing action" do
        @access_controls.stub!(:requires_changes?).and_return(true)
        @access_controls.should_receive(:set_all!)
        @node.normal[:slappiness] = "happiness"
        @provider.should_receive(:backup)
        @provider.run_action(:create_if_missing)
        IO.read(@rendered_file_location).should == "slappiness is happiness"
        @resource.should be_updated_by_last_action
      end

      context "and no access control settings are set on the resource" do
        it "sets access control metadata on the new resource" do
          @access_controls.stub!(:requires_changes?).and_return(false)
          @access_controls.should_receive(:set_all!)
          @node.normal[:slappiness] = "happiness"
          @provider.should_receive(:backup)
          @provider.run_action(:create)
          IO.read(@rendered_file_location).should == "slappiness is happiness"
          @resource.should be_updated_by_last_action

          # Veracity of actual data checked in functional tests
          @resource.owner.should be_a_kind_of(String)
          @resource.group.should be_a_kind_of(String)
          @resource.mode.should be_a_kind_of(String)
        end
      end
    end

    describe "when the target file has the wrong content" do
      before do
        File.open(@rendered_file_location, "w+") { |f| f.print "blargh" }
      end

      it "overwrites the file with the updated content when the create action is run" do
        @node.normal[:slappiness] = "a warm gun"
        @access_controls.stub!(:requires_changes?).and_return(false)
        @access_controls.should_receive(:set_all!)
        @provider.should_receive(:backup)
        @provider.run_action(:create)
        IO.read(@rendered_file_location).should == "slappiness is a warm gun"
        @resource.should be_updated_by_last_action
      end

      it "should set the file access control as specified in the resource" do
        @access_controls.stub!(:requires_changes?).and_return(true)
        @access_controls.should_receive(:set_all!)
        @resource.owner("adam")
        @resource.group("wheel")
        @resource.mode(00644)
        @provider.should_receive(:backup)
        @provider.run_action(:create)
        @resource.should be_updated_by_last_action
      end

      it "doesn't overwrite the file when the create if missing action is run" do
        @access_controls.stub!(:requires_changes?).and_return(false)
        @access_controls.should_not_receive(:set_all!)
        @node.normal[:slappiness] = "a warm gun"
        @provider.should_not_receive(:backup)
        @provider.run_action(:create_if_missing)
        IO.read(@rendered_file_location).should == "blargh"
        @resource.should_not be_updated_by_last_action
      end
    end

    describe "when the target has the correct content" do
      before do
        File.open(@rendered_file_location, "w") { |f| f.print "slappiness is a warm gun" }
        @current_resource.checksum('4ff94a87794ed9aefe88e734df5a66fc8727a179e9496cbd88e3b5ec762a5ee9')
        @access_controls = mock("access controls")
        @provider.stub!(:access_controls).and_return(@access_controls)
      end

      it "does not backup the original or overwrite it" do
        @node.normal[:slappiness] = "a warm gun"
        @access_controls.stub!(:requires_changes?).and_return(false)
        @provider.should_not_receive(:backup)
        FileUtils.should_not_receive(:mv)
        @provider.run_action(:create)
        @resource.should_not be_updated_by_last_action
      end

      it "does not backup the original or overwrite it on create if missing" do
        @node.normal[:slappiness] = "a warm gun"
        @access_controls.stub!(:requires_changes?).and_return(false)
        @provider.should_not_receive(:backup)
        FileUtils.should_not_receive(:mv)
        @provider.run_action(:create)
        @resource.should_not be_updated_by_last_action
      end

      it "sets the file access controls if they have diverged" do
        @provider.stub!(:backup).and_return(true)
        @access_controls.stub!(:requires_changes?).and_return(true)
        @access_controls.should_receive(:set_all!)
        @resource.owner("adam")
        @resource.group("wheel")
        @resource.mode(00644)
        @provider.should_receive(:backup)
        @provider.run_action(:create)
        @resource.should be_updated_by_last_action
      end
    end

  end
end
