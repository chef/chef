#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

describe Chef::Cookbook::Chefignore do
  before do
    @chefignore = Chef::Cookbook::Chefignore.new(File.join(CHEF_SPEC_DATA, "cookbooks"))
  end

  it "loads the globs in the chefignore file" do
    expect(@chefignore.ignores).to match_array(%w{recipes/ignoreme.rb ignored})
  end

  it "removes items from an array that match the ignores" do
    file_list = %w{ recipes/ignoreme.rb recipes/dontignoreme.rb }
    expect(@chefignore.remove_ignores_from(file_list)).to eq(%w{recipes/dontignoreme.rb})
  end

  it "determines if a file is ignored" do
    expect(@chefignore.ignored?("ignored")).to be_truthy
    expect(@chefignore.ignored?("recipes/ignoreme.rb")).to be_truthy
    expect(@chefignore.ignored?("recipes/dontignoreme.rb")).to be_falsey
  end

  context "when using the single cookbook pattern" do
    before do
      @chefignore = Chef::Cookbook::Chefignore.new(File.join(CHEF_SPEC_DATA, "standalone_cookbook"))
    end

    it "loads the globs in the chefignore file" do
      expect(@chefignore.ignores).to match_array(%w{recipes/ignoreme.rb ignored vendor/bundle/*})
    end
  end
end
