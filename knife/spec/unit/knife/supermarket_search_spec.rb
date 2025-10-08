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

require "chef/knife/supermarket_search"
require "knife_spec_helper"

describe Chef::Knife::SupermarketSearch do
  let(:knife) { described_class.new }
  let(:noauth_rest) { double("no auth rest") }
  let(:stdout) { StringIO.new }
  let(:cookbooks_data) {
    [
    { "cookbook_name" => "mysql", "cookbook_maintainer" => "sous-chefs", "cookbook_description" => "Provides mysql_service, mysql_config, and mysql_client resources", "cookbook" => "https://supermarket.chef.io/api/v1/cookbooks/mysql" },
    { "cookbook_name" => "mw_mysql", "cookbook_maintainer" => "car", "cookbook_description" => "Installs/Configures mw_mysql", "cookbook" => "https://supermarket.chef.io/api/v1/cookbooks/mw_mysql" },
    { "cookbook_name" => "L7-mysql", "cookbook_maintainer" => "szelcsanyi", "cookbook_description" => "Installs/Configures MySQL server", "cookbook" => "https://supermarket.chef.io/api/v1/cookbooks/l7-mysql" },
    { "cookbook_name" => "mysql-sys", "cookbook_maintainer" => "ovaistariq", "cookbook_description" => "Installs the mysql-sys tool. Description of the tool is available here https://github.com/MarkLeith/mysql-sys", "cookbook" => "https://supermarket.chef.io/api/v1/cookbooks/mysql-sys" },
    { "cookbook_name" => "cg_mysql", "cookbook_maintainer" => "phai", "cookbook_description" => "Installs/Configures mysql with master and slave", "cookbook" => "https://supermarket.chef.io/api/v1/cookbooks/cg_mysql" },
  ]
  }

  let(:response_text) {
    {
      "start" => 0,
      "total" => 5,
      "items" => cookbooks_data,
    }
  }

  let(:empty_response_text) {
    {
      "start" => 0,
      "total" => 0,
      "items" => [],
    }
  }

  describe "run" do
    before do
      allow(knife.ui).to receive(:stdout).and_return(stdout)
      allow(knife).to receive(:noauth_rest).and_return(noauth_rest)
      knife.configure_chef
    end

    context "when name_args is present" do
      before do
        expect(noauth_rest).to receive(:get).and_return(response_text)
      end

      it "should display cookbooks with given name value" do
        knife.name_args = ["mysql"]
        knife.run
        cookbooks_data.each do |item|
          expect(stdout.string).to match(/#{item["cookbook_name"]}\s/)
        end
      end
    end

    context "when name_args is empty string" do
      before do
        expect(noauth_rest).to receive(:get).and_return(empty_response_text)
      end

      it "display nothing with name arg empty string" do
        knife.name_args = [""]
        knife.run
        expect(stdout.string).to eq("\n")
      end
    end
  end
end
