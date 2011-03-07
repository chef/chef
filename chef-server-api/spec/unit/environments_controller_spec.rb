#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../spec_model_helper')
require 'chef/node'
require 'pp'

describe "Environments controller" do
  before do
    Merb.logger.set_log(StringIO.new)

    @env1 = make_environment("env1")

    @filtered_cookbook_list_env1 = 
      make_filtered_cookbook_hash(make_cookbook("cookbook1", "1.0.0"),
                                  make_cookbook("cookbook2", "1.0.0"))
    @filtered_cookbook_list_env2 = 
      make_filtered_cookbook_hash(make_cookbook("cookbook1", "2.0.0"),
                                  make_cookbook("cookbook2", "2.0.0"))
  end

  describe "when handling Environments API calls" do
    it "should expand the passed-in run_list using the correct environment" do
      # Env1 pins both versions at 1.0.0. Expect only the one we ask for, cookbook1,
      # back in the result.
      Chef::Environment.should_receive(:cdb_load_filtered_cookbook_versions).with("env1").and_return(@filtered_cookbook_list_env1)
      response = post_json("/environments/env1/cookbook_versions", {"run_list" => ["recipe[cookbook1]"]})
      response.should be_kind_of(Hash)
      response.keys.size.should == 1
      response["cookbook1"].should_not == nil
      response["cookbook1"]['version'].should == "1.0.0"
      response["cookbook1"]['url'].should == "#{root_url}/cookbooks/cookbook1/1.0.0"

      # Ask for both cookbook1 and cookbook2 back. Expect version 2.0.0 for
      # each, as those are what's appropriate for the environment.
      Chef::Environment.should_receive(:cdb_load_filtered_cookbook_versions).with("env2").and_return(@filtered_cookbook_list_env2)
      response = post_json("/environments/env2/cookbook_versions", {"run_list" => ["recipe[cookbook2]", "recipe[cookbook1]"]})
      response.should be_kind_of(Hash)
      response.keys.size.should == 2
      response["cookbook1"].should_not == nil
      response["cookbook1"]['version'].should == "2.0.0"
      response["cookbook1"]['url'].should == "#{root_url}/cookbooks/cookbook1/2.0.0"
      response["cookbook2"].should_not == nil
      response["cookbook2"]['version'].should == "2.0.0"
      response["cookbook2"]['url'].should == "#{root_url}/cookbooks/cookbook2/2.0.0"
    end
  end
end

