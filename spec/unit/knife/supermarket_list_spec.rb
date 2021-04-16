#
# Author:: Vivek Singh (<vivek.singh@msystechnologies.com>)
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

require "chef/knife/supermarket_list"
require "knife_spec_helper"

describe Chef::Knife::SupermarketList do
  let(:knife) { described_class.new }
  let(:noauth_rest) { double("no auth rest") }
  let(:stdout) { StringIO.new }
  let(:cookbooks_data) {
    [
    { "cookbook_name" => "1password", "cookbook_maintainer" => "jtimberman", "cookbook_description" => "Installs 1password", "cookbook" => "https://supermarket.chef.io/api/v1/cookbooks/1password" },
    { "cookbook_name" => "301", "cookbook_maintainer" => "markhuge", "cookbook_description" => "Installs/Configures 301", "cookbook" => "https://supermarket.chef.io/api/v1/cookbooks/301" },
    { "cookbook_name" => "3cx", "cookbook_maintainer" => "obay", "cookbook_description" => "Installs/Configures 3cx", "cookbook" => "https://supermarket.chef.io/api/v1/cookbooks/3cx" },
    { "cookbook_name" => "7dtd", "cookbook_maintainer" => "gregf", "cookbook_description" => "Installs/Configures the 7 Days To Die server", "cookbook" => "https://supermarket.chef.io/api/v1/cookbooks/7dtd" },
    { "cookbook_name" => "7-zip", "cookbook_maintainer" => "sneal", "cookbook_description" => "Installs/Configures the 7-zip file archiver", "cookbook" => "https://supermarket.chef.io/api/v1/cookbooks/7-zip" },
  ]
  }

  let(:response_text) {
    {
      "start" => 0,
      "total" => 5,
      "items" => cookbooks_data,
    }
  }

  describe "run" do
    before do
      allow(knife.ui).to receive(:stdout).and_return(stdout)
      allow(knife).to receive(:noauth_rest).and_return(noauth_rest)
      expect(noauth_rest).to receive(:get).and_return(response_text)
      knife.configure_chef
    end

    it "should display all supermarket cookbooks" do
      knife.run
      cookbooks_data.each do |item|
        expect(stdout.string).to match(/#{item["cookbook_name"]}\s/)
      end
    end

    describe "with -w or --with-uri" do
      it "should display the cookbook uris" do
        knife.config[:with_uri] = true
        knife.run
        cookbooks_data.each do |item|
          expect(stdout.string).to match(/#{item["cookbook_name"]}\s/)
          expect(stdout.string).to match(/#{item["cookbook"]}\s/)
        end
      end
    end
  end
end
