#
# Author:: Jeremy Miller (<jm@chef.io>)
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
require "lib/chef/chef_fs/data_handler/data_handler_base"

describe Chef::ChefFS::DataHandler::DataHandlerBase do
  describe "#normalize_hash" do
    let(:some_item) do
      { "name" => "grizzly",
        "gender" => "female",
        "age" => 3,
        "food" => "honey",
      }
    end

    let(:item_defaults) do
      { "family" => "ursidae",
        "hibernate" => true,
        "food" => "berries",
        "avg_lifespan_years" => 22,
      }
    end

    let(:normalized) do
      { "name" => "grizzly",
        "gender" => "female",
        "family" => "ursidae",
        "hibernate" => true,
        "avg_lifespan_years" => 22,
        "age" => 3,
        "food" => "honey",
      }
    end

    let(:handler) { described_class.new }

    it "normalizes the Hash, filling in default values" do
      expect(handler.normalize_hash(some_item, item_defaults)).to eq(normalized)
    end

    it "prefers already existing values over default values" do
      expect(handler.normalize_hash(some_item, item_defaults)["food"]).to eq("honey")
    end

    it "handles being passed a nil value instead of Hash" do
      expect(handler.normalize_hash(nil, item_defaults)).to eq(item_defaults)
    end
  end
end
