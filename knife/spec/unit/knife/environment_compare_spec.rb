#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright 2013-2016, Sander Botman.
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

describe Chef::Knife::EnvironmentCompare do
  before(:each) do
    @knife = Chef::Knife::EnvironmentCompare.new

    @environments = {
      "cita" => "http://localhost:4000/environments/cita",
      "citm" => "http://localhost:4000/environments/citm",
    }

    allow(@knife).to receive(:environment_list).and_return(@environments)

    @constraints = {
      "cita" => { "foo" => "= 1.0.1", "bar" => "= 0.0.4" },
      "citm" => { "foo" => "= 1.0.1", "bar" => "= 0.0.2" },
    }

    allow(@knife).to receive(:constraint_list).and_return(@constraints)

    @cookbooks = { "foo" => "= 1.0.1", "bar" => "= 0.0.1" }

    allow(@knife).to receive(:cookbook_list).and_return(@cookbooks)

    @rest_double = double("rest")
    allow(@knife).to receive(:rest).and_return(@rest_double)
    @cookbook_names = %w{apache2 mysql foo bar dummy chef_handler}
    @base_url = "https://server.example.com/cookbooks"
    @cookbook_data = {}
    @cookbook_names.each do |item|
      @cookbook_data[item] = { "url" => "#{@base_url}/#{item}",
                               "versions" => [{ "version" => "1.0.1",
                                                "url" => "#{@base_url}/#{item}/1.0.1" }] }
    end

    allow(@rest_double).to receive(:get).with("/cookbooks?num_versions=1").and_return(@cookbook_data)

    @stdout = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
  end

  describe "run" do
    it "should display only cookbooks with version constraints" do
      @knife.config[:format] = "summary"
      @knife.run
      @environments.each_key do |item|
        expect(@stdout.string).to(match(/#{item}/)) && expect(@stdout.string.lines.count).to(be 4)
      end
    end

    it "should display 4 number of lines" do
      @knife.config[:format] = "summary"
      @knife.run
      expect(@stdout.string.lines.count).to be 4
    end
  end

  describe "with -m or --mismatch" do
    it "should display only cookbooks that have mismatching version constraints" do
      @knife.config[:format] = "summary"
      @knife.config[:mismatch] = true
      @knife.run
      @constraints.each_value do |ver|
        expect(@stdout.string).to match(/#{ver[1]}/)
      end
    end

    it "should display 3 number of lines" do
      @knife.config[:format] = "summary"
      @knife.config[:mismatch] = true
      @knife.run
      expect(@stdout.string.lines.count).to be 3
    end
  end

  describe "with -a or --all" do
    it "should display all cookbooks" do
      @knife.config[:format] = "summary"
      @knife.config[:all] = true
      @knife.run
      @constraints.each_value do |ver|
        expect(@stdout.string).to match(/#{ver[1]}/)
      end
    end

    it "should display 8 number of lines" do
      @knife.config[:format] = "summary"
      @knife.config[:all] = true
      @knife.run
      expect(@stdout.string.lines.count).to be 8
    end
  end

end
