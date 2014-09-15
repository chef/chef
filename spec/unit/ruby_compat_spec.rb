#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require File.expand_path('../../spec_helper', __FILE__)
require 'chef/ruby_compat'
require 'chef/role'
require 'chef/environment'

describe Chef::RubyCompat do
  
  describe "#to_ruby with Chef::Role" do
 
  	let(:role) do
  	  role = Chef::Role.new

  	  role.name "name"
  	  role.description "a description"

  	  role.default_attributes "attr1" => "val1", "attr2" => "val2"
  	  role.override_attributes "attr3" => "val3", "attr4" => "val4"

  	  role.run_list "recipe[cookbook]", "role[role]"

  	  role
  	end

    it "returns ruby code that evaluates to the same role" do
      new_role = Chef::Role.new
      new_role.instance_eval(Chef::RubyCompat.to_ruby(role))

      expect(role.name).to eq new_role.name
      expect(role.description).to eq new_role.description
      expect(role.default_attributes).to eq new_role.default_attributes
      expect(role.override_attributes).to eq new_role.override_attributes
      expect(role.env_run_lists).to eq new_role.env_run_lists
    end

    describe "with environment run lists" do

      let(:role_env_runlists) do
        role_env_runlists = Chef::Role.new.update_from! role

        # update_from! does not include the name
		role_env_runlists.name "name"
		
        role_env_runlists.env_run_lists "_default" => ["recipe[cookbook1]", "recipe[cookbook2]"], "env1" => ["recipe[cookbook3]"], "env2" => ["recipe[cookbook4]"]

        role_env_runlists
      end


      it "returns ruby code that evaluates to the same role" do
        new_role = Chef::Role.new
        new_role.instance_eval(Chef::RubyCompat.to_ruby(role_env_runlists))

        expect(role_env_runlists.name).to eq new_role.name
        expect(role_env_runlists.description).to eq new_role.description
        expect(role_env_runlists.default_attributes).to eq new_role.default_attributes
        expect(role_env_runlists.override_attributes).to eq new_role.override_attributes
        expect(role_env_runlists.env_run_lists).to eq new_role.env_run_lists
      end

    end

  end

  describe "#to_ruby with Chef::Environment" do

    let(:env) do
      env = Chef::Environment.new 

      env.name "name"
      env.description "a description"

	  env.default_attributes "attr1" => "val1", "attr2" => "val2"
  	  env.override_attributes "attr3" => "val3", "attr4" => "val4"

  	  env.cookbook "cookbook1", "= 1.0.0"
  	  env.cookbook "cookbook2", ">= 2.0.0"

      env
    end

    it "returns ruby code that evaluates to the same environment" do
      new_env = Chef::Environment.new
      new_env.instance_eval(Chef::RubyCompat.to_ruby(env))

      expect(env.name).to eq new_env.name
      expect(env.description).to eq new_env.description
      expect(env.default_attributes).to eq new_env.default_attributes
      expect(env.override_attributes).to eq new_env.override_attributes
      expect(env.cookbook_versions).to eq new_env.cookbook_versions
    end

  end

  describe "#to_ruby with something not supported" do

    it "raises an ArgumentError" do
      expect { Chef::RubyCompat.to_ruby("")}.to raise_error(ArgumentError)
    end

  end

end