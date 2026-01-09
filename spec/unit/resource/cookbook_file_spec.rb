#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# p License:: Apache License, Version 2.0
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

describe Chef::Resource::CookbookFile do
  let(:resource) { Chef::Resource::CookbookFile.new("/foo/bar/sourcecode_tarball.tgz") }

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :create_if_missing, :delete, :touch actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :create_if_missing }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :touch }.not_to raise_error
  end

  it "uses the basepath of the resource name for the source property" do
    expect(resource.source).to eq("sourcecode_tarball.tgz")
  end

  it "source property accepts Strings" do
    resource.source("config_file.conf")
    expect(resource.source).to eq("config_file.conf")
  end

  it "cookbook property defaults to nil (current cookbook will be used)" do
    expect(resource.cookbook).to be_nil
  end

  it "has a cookbook property that accepts Strings" do
    resource.cookbook("munin")
    expect(resource.cookbook).to eq("munin")
  end

  describe "when it has a backup number, group, mode, owner, source, checksum, and cookbook on nix or path, rights, deny_rights, checksum on windows" do
    before do
      if ChefUtils.windows?
        resource.path("C:/temp/origin/file.txt")
        resource.rights(:read, "Everyone")
        resource.deny_rights(:full_control, "Clumsy_Sam")
      else
        resource.path("/tmp/origin/file.txt")
        resource.group("wheel")
        resource.mode("0664")
        resource.owner("root")
        resource.source("/tmp/foo.txt")
        resource.cookbook("/tmp/cookbooks/cooked.rb")
      end
      resource.checksum("1" * 64)
    end

    it "describes the state" do
      state = resource.state_for_resource_reporter
      if ChefUtils.windows?
        puts state
        expect(state[:rights]).to eq([{ permissions: :read, principals: "Everyone" }])
        expect(state[:deny_rights]).to eq([{ permissions: :full_control, principals: "Clumsy_Sam" }])
      else
        expect(state[:group]).to eq("wheel")
        expect(state[:mode]).to eq("0664")
        expect(state[:owner]).to eq("root")
      end
      expect(state[:checksum]).to eq("1" * 64)
    end

    it "returns the path as its identity" do
      if ChefUtils.windows?
        expect(resource.identity).to eq("C:/temp/origin/file.txt")
      else
        expect(resource.identity).to eq("/tmp/origin/file.txt")
      end
    end
  end
end
