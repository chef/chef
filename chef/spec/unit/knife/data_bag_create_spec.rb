#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

module ChefSpecs
  class ChefRest
    attr_reader :args_received
    def initialize
      @args_received = []
    end
    
    def post_rest(*args)
      @args_received << args
    end
  end
end


describe Chef::Knife::DataBagCreate do
  before do
    @knife = Chef::Knife::DataBagCreate.new
    @rest = ChefSpecs::ChefRest.new
    @knife.stub!(:rest).and_return(@rest)
    @log = Chef::Log
  end


  it "creates a data bag when given one argument" do
    # TODO: OMG use accessors, especially when you didn't set the GDMF ivar, kthx
    @knife.instance_variable_set(:@name_args, ['sudoing_admins'])
    @rest.should_receive(:post_rest).with("data", {"name" => "sudoing_admins"})
    @log.should_receive(:info).with("Created data_bag[sudoing_admins]")

    @knife.run
  end

  it "creates a data bag item when given two arguments" do
    @knife.instance_variable_set(:@name_args, ['sudoing_admins', 'ME'])
    user_supplied_json = {"login_name" => "alphaomega", "id" => "ME"}.to_json
    @knife.should_receive(:create_object).and_yield(user_supplied_json)
    @rest.should_receive(:post_rest).with("data", {'name' => 'sudoing_admins'}).ordered
    @rest.should_receive(:post_rest).with("data/sudoing_admins", user_supplied_json).ordered

    @knife.run
  end

end
