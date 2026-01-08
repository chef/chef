#
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
require "chef/dsl/render_helpers"

describe Chef::DSL::RenderHelpers do

  hash = {
          "golf": "hotel",
          "kilo": %w{lima mike},
          "india": {
                    "juliett": "blue",
                   },
          "alpha": {
                    "charlie": true,
                    "bravo": 10,
                   },
          "echo": "foxtrot",
         }

  context "render_json" do
    json = Chef::DSL::RenderHelpers.render_json(hash)
    describe "JSON content" do
      it "expected JSON output" do
        expected = <<-EXPECTED
{
  "golf": "hotel",
  "kilo": [
    "lima",
    "mike"
  ],
  "india": {
    "juliett": "blue"
  },
  "alpha": {
    "charlie": true,
    "bravo": 10
  },
  "echo": "foxtrot"
}
        EXPECTED
        expect(json).to eq(expected)
      end
    end
  end

  context "render_toml" do
    toml = Chef::DSL::RenderHelpers.render_toml(hash)
    describe "TOML content" do
      it "expected TOML output" do
        expected = <<-EXPECTED
echo = "foxtrot"
golf = "hotel"
kilo = ["lima", "mike"]
[alpha]
bravo = 10
charlie = true
[india]
juliett = "blue"
        EXPECTED
        expect(toml).to eq(expected)
      end
    end
  end

  context "render_yaml" do
    yaml = Chef::DSL::RenderHelpers.render_yaml(hash)
    describe "YAML content" do
      it "expected YAML output" do
        expected = <<-EXPECTED
---
golf: hotel
kilo:
- lima
- mike
india:
  juliett: blue
alpha:
  charlie: true
  bravo: 10
echo: foxtrot
        EXPECTED
        expect(yaml).to eq(expected)
      end
    end
  end
end
