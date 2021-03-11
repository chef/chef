#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Will Albenzi (<walbenzi@gmail.com>)
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

require "knife_spec_helper"

describe Chef::Knife::RoleEnvRunListAdd do
  before(:each) do
    #    Chef::Config[:role_name]  = "websimian"
    #    Chef::Config[:env_name]  = "QA"
    @knife = Chef::Knife::RoleEnvRunListAdd.new
    @knife.config = {
      after: nil,
    }
    @knife.name_args = [ "will", "QA", "role[monkey]" ]
    allow(@knife).to receive(:output).and_return(true)
    @role = Chef::Role.new
    allow(@role).to receive(:save).and_return(true)
    allow(Chef::Role).to receive(:load).and_return(@role)
  end

  describe "run" do

    #    it "should display all the things" do
    #      @knife.run
    #      @role.to_json.should == 'show all the things'
    #    end

    it "should have an empty default run list" do
      @knife.run
      expect(@role.run_list[0]).to be_nil
    end

    it "should have a QA environment" do
      @knife.run
      expect(@role.active_run_list_for("QA")).to eq("QA")
    end

    it "should load the role named will" do
      expect(Chef::Role).to receive(:load).with("will")
      @knife.run
    end

    it "should be able to add an environment specific run list" do
      @knife.run
      expect(@role.run_list_for("QA")[0]).to eq("role[monkey]")
    end

    it "should save the role" do
      expect(@role).to receive(:save)
      @knife.run
    end

    it "should print the run list" do
      expect(@knife).to receive(:output).and_return(true)
      @knife.run
    end

    describe "with -a or --after specified" do
      it "should not create a change if the specified 'after' never comes" do
        @role.run_list_for("_default") << "role[acorns]"
        @role.run_list_for("_default") << "role[barn]"
        @knife.config[:after] = "role[acorns]"
        @knife.name_args = [ "will", "QA", "role[pad]" ]
        @knife.run
        expect(@role.run_list_for("QA")[0]).to be_nil
        expect(@role.run_list[0]).to eq("role[acorns]")
        expect(@role.run_list[1]).to eq("role[barn]")
        expect(@role.run_list[2]).to be_nil
      end

      it "should add to the run list after the specified entries in the QA run list" do
        # Setup
        @role.run_list_for("_default") << "role[acorns]"
        @role.run_list_for("_default") << "role[barn]"
        @knife.run
        @role.run_list_for("QA") << "role[pencil]"
        @role.run_list_for("QA") << "role[pen]"
        # Configuration we are testing
        @knife.config[:after] = "role[pencil]"
        @knife.name_args = [ "will", "QA", "role[pad]", "role[whackadoo]" ]
        @knife.run
        # The actual tests
        expect(@role.run_list_for("QA")[0]).to eq("role[monkey]")
        expect(@role.run_list_for("QA")[1]).to eq("role[pencil]")
        expect(@role.run_list_for("QA")[2]).to eq("role[pad]")
        expect(@role.run_list_for("QA")[3]).to eq("role[whackadoo]")
        expect(@role.run_list_for("QA")[4]).to eq("role[pen]")
        expect(@role.run_list[0]).to eq("role[acorns]")
        expect(@role.run_list[1]).to eq("role[barn]")
        expect(@role.run_list[2]).to be_nil
      end
    end

    describe "with more than one role or recipe" do
      it "should add to the QA run list all the entries" do
        @knife.name_args = [ "will", "QA", "role[monkey],role[duck]" ]
        @role.run_list_for("_default") << "role[acorns]"
        @knife.run
        expect(@role.run_list_for("QA")[0]).to eq("role[monkey]")
        expect(@role.run_list_for("QA")[1]).to eq("role[duck]")
        expect(@role.run_list[0]).to eq("role[acorns]")
        expect(@role.run_list[1]).to be_nil
      end
    end

    describe "with more than one role or recipe with space between items" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "will", "QA", "role[monkey], role[duck]" ]
        @role.run_list_for("_default") << "role[acorns]"
        @knife.run
        expect(@role.run_list_for("QA")[0]).to eq("role[monkey]")
        expect(@role.run_list_for("QA")[1]).to eq("role[duck]")
        expect(@role.run_list[0]).to eq("role[acorns]")
        expect(@role.run_list[1]).to be_nil
      end
    end

    describe "with more than one role or recipe as different arguments" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "will", "QA", "role[monkey]", "role[duck]" ]
        @role.run_list_for("_default") << "role[acorns]"
        @knife.run
        expect(@role.run_list_for("QA")[0]).to eq("role[monkey]")
        expect(@role.run_list_for("QA")[1]).to eq("role[duck]")
        expect(@role.run_list[0]).to eq("role[acorns]")
        expect(@role.run_list[1]).to be_nil
      end
    end

    describe "with more than one role or recipe as different arguments and list separated by comas" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "will", "QA", "role[monkey]", "role[duck],recipe[bird::fly]" ]
        @role.run_list_for("_default") << "role[acorns]"
        @knife.run
        expect(@role.run_list_for("QA")[0]).to eq("role[monkey]")
        expect(@role.run_list_for("QA")[1]).to eq("role[duck]")
        expect(@role.run_list_for("QA")[2]).to eq("recipe[bird::fly]")
        expect(@role.run_list[0]).to eq("role[acorns]")
        expect(@role.run_list[1]).to be_nil
      end
    end

    describe "Recipe with version number is allowed" do
      it "should add to the run list all the entries including the versioned recipe" do
        @knife.name_args = [ "will", "QA", "role[monkey]", "role[duck],recipe[bird::fly@1.1.3]" ]
        @role.run_list_for("_default") << "role[acorns]"
        @knife.run
        expect(@role.run_list_for("QA")[0]).to eq("role[monkey]")
        expect(@role.run_list_for("QA")[1]).to eq("role[duck]")
        expect(@role.run_list_for("QA")[2]).to eq("recipe[bird::fly@1.1.3]")
        expect(@role.run_list[0]).to eq("role[acorns]")
        expect(@role.run_list[1]).to be_nil
      end
    end

    describe "with one role or recipe but with an extraneous comma" do
      it "should add to the run list one item" do
        @role.run_list_for("_default") << "role[acorns]"
        @knife.name_args = [ "will", "QA", "role[monkey]," ]
        @knife.run
        expect(@role.run_list_for("QA")[0]).to eq("role[monkey]")
        expect(@role.run_list_for("QA")[1]).to be_nil
        expect(@role.run_list[0]).to eq("role[acorns]")
        expect(@role.run_list[1]).to be_nil
      end
    end

    describe "with more than one command" do
      it "should be able to the environment run list by running multiple knife commands" do
        @knife.name_args = [ "will", "QA", "role[blue]," ]
        @knife.run
        @knife.name_args = [ "will", "QA", "role[black]," ]
        @knife.run
        expect(@role.run_list_for("QA")[0]).to eq("role[blue]")
        expect(@role.run_list_for("QA")[1]).to eq("role[black]")
        expect(@role.run_list[0]).to be_nil
      end
    end

    describe "with more than one environment" do
      it "should add to the run list a second environment in the specific run list" do
        @role.run_list_for("_default") << "role[acorns]"
        @knife.name_args = [ "will", "QA", "role[blue]," ]
        @knife.run
        @role.run_list_for("QA") << "role[walnuts]"

        @knife.name_args = [ "will", "PRD", "role[ball]," ]
        @knife.run
        @role.run_list_for("PRD") << "role[pen]"

        expect(@role.run_list_for("QA")[0]).to eq("role[blue]")
        expect(@role.run_list_for("PRD")[0]).to eq("role[ball]")
        expect(@role.run_list_for("QA")[1]).to eq("role[walnuts]")
        expect(@role.run_list_for("PRD")[1]).to eq("role[pen]")
        expect(@role.run_list[0]).to eq("role[acorns]")
        expect(@role.run_list[1]).to be_nil
      end
    end

  end
end
