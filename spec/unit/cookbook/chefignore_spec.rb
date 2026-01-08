#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  let(:chefignore) { described_class.new(File.join(CHEF_SPEC_DATA, "cookbooks")) }

  it "loads the globs in the chefignore file" do
    expect(chefignore.ignores).to match_array(%w{recipes/ignoreme.rb ignored})
  end

  it "removes items from an array that match the ignores" do
    file_list = %w{ recipes/ignoreme.rb recipes/dontignoreme.rb }
    expect(chefignore.remove_ignores_from(file_list)).to eq(%w{recipes/dontignoreme.rb})
  end

  it "determines if a file is ignored" do
    expect(chefignore.ignored?("ignored")).to be_truthy
    expect(chefignore.ignored?("recipes/ignoreme.rb")).to be_truthy
    expect(chefignore.ignored?("recipes/dontignoreme.rb")).to be_falsey
  end

  context "when using the single cookbook pattern" do
    let(:chefignore) { described_class.new(File.join(CHEF_SPEC_DATA, "cookbooks/starter")) }

    it "loads the globs in the chefignore file" do
      expect(chefignore.ignores).to match_array(%w{recipes/default.rb ignored})
    end
  end

  context "when cookbook has it's own chefignore" do
    let(:chefignore) { described_class.new(File.join(CHEF_SPEC_DATA, "cookbooks/starter")) }

    it "loads the globs in the chefignore file" do
      expect(chefignore.ignores).to match_array(%w{recipes/default.rb ignored})
    end
  end

  context "when cookbook don't have own chefignore" do
    let(:chefignore) { described_class.new(File.join(CHEF_SPEC_DATA, "cookbooks/apache2")) }

    it "loads the globs in the chefignore file of cookbooks dir" do
      expect(chefignore.ignores).to match_array(%w{recipes/ignoreme.rb ignored})
    end
  end

  context "when using the single cookbook pattern" do
    let(:chefignore) { described_class.new(File.join(CHEF_SPEC_DATA, "standalone_cookbook")) }

    it "loads the globs in the chefignore file" do
      expect(chefignore.ignores).to match_array(%w{recipes/ignoreme.rb ignored vendor/bundle/*})
    end
  end
end
