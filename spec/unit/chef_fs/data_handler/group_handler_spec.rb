#
# Author:: Ryan Cragun (<ryan@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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
require "lib/chef/chef_fs/data_handler/group_data_handler"

class TestEntry < Mash
  attr_accessor :name, :org

  def initialize(name, org)
    @name = name
    @org = org
  end
end

describe Chef::ChefFS::DataHandler::GroupDataHandler do
  describe "#normalize_for_post" do
    let(:entry) do
      TestEntry.new("workers.json", "hive")
    end

    let(:group) do
      { "name" => "worker_bees",
        "clients" => %w{honey sting},
        "users" => %w{fizz buzz},
        "actors" => %w{honey},
      }
    end

    let(:normalized) do
      { "actors" =>
          { "users" => %w{fizz buzz},
            "clients" => %w{honey sting},
            "groups" => [],
          },
        "groupname" => "workers",
        "name" => "worker_bees",
        "orgname" => "hive",
      }
    end

    let(:handler) { described_class.new }

    it "normalizes the users, clients and groups into actors" do
      expect(handler.normalize_for_post(group, entry)).to eq(normalized)
    end
  end
end
