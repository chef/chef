#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Will Albenzi (<walbenzi@gmail.com>)
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

describe Chef::Knife::RoleRunListAdd do
  before(:each) do
#    Chef::Config[:role_name]  = "websimian"
#    Chef::Config[:env_name]  = "QA"
    @knife = Chef::Knife::RoleRunListAdd.new
    @knife.config = {
      :after => nil
    }
    @knife.name_args = [ "will", "role[monkey]" ]
    @knife.stub!(:output).and_return(true)
    @role = Chef::Role.new() 
    @role.stub!(:save).and_return(true)
    Chef::Role.stub!(:load).and_return(@role)
  end

  describe "run" do

#    it "should display all the things" do
#      @knife.run
#      @role.to_json.should == 'show all the things'
#    end

    it "should have a run list with the monkey role" do
      @knife.run
      @role.run_list[0].should == "role[monkey]"
    end

    it "should load the role named will" do
      Chef::Role.should_receive(:load).with("will")
      @knife.run
    end

    it "should save the role" do
      @role.should_receive(:save)
      @knife.run
    end

    it "should print the run list" do
      @knife.should_receive(:output).and_return(true)
      @knife.run
    end

    describe "with -a or --after specified" do
      it "should not create a change if the specified 'after' never comes" do
        @role.run_list_for("_default") << "role[acorns]"
        @role.run_list_for("_default") << "role[barn]"
        @knife.config[:after] = "role[tree]"
        @knife.name_args = [ "will", "role[pad]" ]
        @knife.run
        @role.run_list[0].should == "role[acorns]"
        @role.run_list[1].should == "role[barn]"
        @role.run_list[2].should be_nil
      end

      it "should add to the run list after the specified entries in the default run list" do
        #Setup
        @role.run_list_for("_default") << "role[acorns]"
        @role.run_list_for("_default") << "role[barn]"
        #Configuration we are testing
        @knife.config[:after] = "role[acorns]"
        @knife.name_args = [ "will", "role[pad]", "role[whackadoo]" ]
        @knife.run
        #The actual tests
        @role.run_list[0].should == "role[acorns]"
        @role.run_list[1].should == "role[pad]"
        @role.run_list[2].should == "role[whackadoo]"
        @role.run_list[3].should == "role[barn]"
        @role.run_list[4].should be_nil
      end
    end

    describe "with more than one role or recipe" do
      it "should add to the QA run list all the entries" do
        @knife.name_args = [ "will", "role[monkey],role[duck]" ]
        @role.run_list_for("_default") << "role[acorns]"
        @knife.run
        @role.run_list[0].should == "role[acorns]"
        @role.run_list[1].should == "role[monkey]"
        @role.run_list[2].should == "role[duck]"
        @role.run_list[3].should be_nil
      end
    end

    describe "with more than one role or recipe with space between items" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "will", "role[monkey], role[duck]" ]
        @role.run_list_for("_default") << "role[acorns]"
        @knife.run
        @role.run_list[0].should == "role[acorns]"
        @role.run_list[1].should == "role[monkey]"
        @role.run_list[2].should == "role[duck]"
        @role.run_list[3].should be_nil
      end
    end

    describe "with more than one role or recipe as different arguments" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "will", "role[monkey]", "role[duck]" ]
        @role.run_list_for("_default") << "role[acorns]"
        @knife.run
        @role.run_list[0].should == "role[acorns]"
        @role.run_list[1].should == "role[monkey]"
        @role.run_list[2].should == "role[duck]"
        @role.run_list[3].should be_nil
      end
    end

    describe "with more than one role or recipe as different arguments and list separated by comas" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "will", "role[monkey]", "role[duck],recipe[bird::fly]" ]
        @role.run_list_for("_default") << "role[acorns]"
        @knife.run
        @role.run_list[0].should == "role[acorns]"
        @role.run_list[1].should == "role[monkey]"
        @role.run_list[2].should == "role[duck]"
        @role.run_list[3].should == "recipe[bird::fly]"
        @role.run_list[4].should be_nil
      end
    end

    describe "Recipe with version number is allowed" do
      it "should add to the run list all the entries including the versioned recipe" do
        @knife.name_args = [ "will", "role[monkey]", "role[duck],recipe[bird::fly@1.1.3]" ]
        @role.run_list_for("_default") << "role[acorns]"
        @knife.run
        @role.run_list[0].should == "role[acorns]"
        @role.run_list[1].should == "role[monkey]"
        @role.run_list[2].should == "role[duck]"
        @role.run_list[3].should == "recipe[bird::fly@1.1.3]"
        @role.run_list[4].should be_nil
      end
    end

    describe "with one role or recipe but with an extraneous comma" do
      it "should add to the run list one item" do
        @role.run_list_for("_default") << "role[acorns]"
        @knife.name_args = [ "will", "role[monkey]," ]
        @knife.run
        @role.run_list[0].should == "role[acorns]"
        @role.run_list[1].should == "role[monkey]"
        @role.run_list[2].should be_nil
      end
    end
    
    describe "with more than one command" do
      it "should be able to the environment run list by running multiple knife commands" do
        @knife.name_args = [ "will", "role[blue]," ]
        @knife.run
        @knife.name_args = [ "will", "role[black]," ]
        @knife.run
        @role.run_list[0].should == "role[blue]"
        @role.run_list[1].should == "role[black]"
        @role.run_list[2].should be_nil
      end
    end

  end
end
