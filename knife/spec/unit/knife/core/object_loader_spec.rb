#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Juanje Ojeda (<juanje.ojeda@gmail.com>)
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
require "chef/knife/core/object_loader"

describe Chef::Knife::Core::ObjectLoader do
  before(:each) do
    @knife = Chef::Knife.new
    @stdout = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
    Dir.chdir(File.join(CHEF_SPEC_DATA, "object_loader"))
  end

  shared_examples_for "Chef object" do |chef_class|
    it "should create a #{chef_class} object" do
      expect(@object).to be_a_kind_of(chef_class)
    end

    it "should has a attribute 'name'" do
      expect(@object.name).to eql("test")
    end
  end

  {
    "nodes" => Chef::Node,
    "roles" => Chef::Role,
    "environments" => Chef::Environment,
  }.each do |repo_location, chef_class|

    describe "when the file is a #{chef_class}" do
      before do
        @loader = Chef::Knife::Core::ObjectLoader.new(chef_class, @knife.ui)
      end

      describe "when the file is a Ruby" do
        before do
          @object = @loader.load_from(repo_location, "test.rb")
        end

        it_behaves_like "Chef object", chef_class
      end

      # NOTE: This is check for the bug described at CHEF-2352
      describe "when the file is a JSON" do
        describe "and it has defined 'json_class'" do
          before do
            @object = @loader.load_from(repo_location, "test_json_class.json")
          end

          it_behaves_like "Chef object", chef_class
        end

        describe "and it has not defined 'json_class'" do
          before do
            @object = @loader.load_from(repo_location, "test.json")
          end

          it_behaves_like "Chef object", chef_class
        end
      end
    end
  end

end
