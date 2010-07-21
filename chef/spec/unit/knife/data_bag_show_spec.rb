#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::Knife::DataBagShow do
  before do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::DataBagShow.new
    @rest = mock("Chef::REST")
    @knife.stub!(:rest).and_return(@rest)
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
  end


  it "prints the ids of the data bag items in the databag when given only the name of the databag as an argument" do
    @knife.instance_variable_set(:@name_args, ['bag_o_data'])
    data_bag_contents = {"baz"=>"http://localhost:4000/data/bag_o_data/baz", "qux"=>"http://localhost:4000/data/bag_o_data/qux"}
    Chef::DataBag.should_receive(:load).and_return(data_bag_contents)
    

    expected = %q|[
  "baz",
  "qux"
]|
    @knife.run
    @stdout.string.strip.should == expected
  end

  it "prints the contents of the databag item when given the name of the databag and the item as arguments" do
    @knife.instance_variable_set(:@name_args, ['bag_o_data', 'an_item'])
    data_item_content = {"id" => "an_item", "zsh" => "victory_through_tabbing"}

    Chef::DataBagItem.should_receive(:load).with('bag_o_data', 'an_item').and_return(data_item_content)

    @knife.run
    JSON.parse(@stdout.string).should == data_item_content
  end

end
