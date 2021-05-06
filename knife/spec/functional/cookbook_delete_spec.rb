#
# Author:: Daniel DeLeo (<dan@chef.io>)
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

require "knife_spec_helper"
require "tiny_server"

describe Chef::Knife::CookbookDelete do
  let(:server) { TinyServer::Manager.new }
  let(:api) { TinyServer::API.instance }
  let(:knife_stdout) { StringIO.new }
  let(:knife_stderr) { StringIO.new }
  let(:knife) do
    knife = Chef::Knife::CookbookDelete.new
    allow(knife.ui).to receive(:stdout).and_return(knife_stdout)
    allow(knife.ui).to receive(:stderr).and_return(knife_stderr)
    knife
  end

  before(:each) do
    server.start
    api.clear

    Chef::Config[:node_name] = nil
    Chef::Config[:client_key] = nil
    Chef::Config[:chef_server_url] = "http://localhost:9000"
  end

  after(:each) do
    server.stop
  end

  context "when the cookbook doesn't exist" do
    before do
      knife.name_args = %w{no-such-cookbook}
      api.get("/cookbooks/no-such-cookbook", 404, Chef::JSONCompat.to_json({ "error" => "dear Tim, no. -Sent from my iPad" }))
    end

    it "logs an error and exits" do
      expect { knife.run }.to raise_error(SystemExit)
      expect(knife_stderr.string).to match(/Cannot find a cookbook named no-such-cookbook to delete/)
    end

  end

  context "when there is only one version of a cookbook" do
    before do
      knife.name_args = %w{obsolete-cookbook}
      @cookbook_list = { "obsolete-cookbook" => { "versions" => ["version" => "1.0.0"] } }
      api.get("/cookbooks/obsolete-cookbook", 200, Chef::JSONCompat.to_json(@cookbook_list))
    end

    it "asks for confirmation, then deletes the cookbook" do
      stdin, stdout = StringIO.new("y\n"), StringIO.new
      allow(knife.ui).to receive(:stdin).and_return(stdin)
      allow(knife.ui).to receive(:stdout).and_return(stdout)

      cb100_deleted = false
      api.delete("/cookbooks/obsolete-cookbook/1.0.0", 200) { cb100_deleted = true; "[\"true\"]" }

      knife.run

      expect(stdout.string).to match(/#{Regexp.escape('Do you really want to delete obsolete-cookbook version 1.0.0? (Y/N)')}/)
      expect(cb100_deleted).to be_truthy
    end

    it "asks for confirmation before purging" do
      knife.config[:purge] = true

      stdin, stdout = StringIO.new("y\ny\n"), StringIO.new
      allow(knife.ui).to receive(:stdin).and_return(stdin)
      allow(knife.ui).to receive(:stdout).and_return(stdout)

      cb100_deleted = false
      api.delete("/cookbooks/obsolete-cookbook/1.0.0?purge=true", 200) { cb100_deleted = true; "[\"true\"]" }

      knife.run

      expect(stdout.string).to match(/#{Regexp.escape('Are you sure you want to purge files')}/)
      expect(stdout.string).to match(/#{Regexp.escape('Do you really want to delete obsolete-cookbook version 1.0.0? (Y/N)')}/)
      expect(cb100_deleted).to be_truthy

    end

  end

  context "when there are several versions of a cookbook" do
    before do
      knife.name_args = %w{obsolete-cookbook}
      versions = ["1.0.0", "1.1.0", "1.2.0"]
      with_version = lambda { |version| { "version" => version } }
      @cookbook_list = { "obsolete-cookbook" => { "versions" => versions.map(&with_version) } }
      api.get("/cookbooks/obsolete-cookbook", 200, Chef::JSONCompat.to_json(@cookbook_list))
    end

    it "deletes all versions of a cookbook when given the '-a' flag" do
      knife.config[:all] = true
      knife.config[:yes] = true
      cb100_deleted = cb110_deleted = cb120_deleted = nil
      api.delete("/cookbooks/obsolete-cookbook/1.0.0", 200) { cb100_deleted = true; "[\"true\"]" }
      api.delete("/cookbooks/obsolete-cookbook/1.1.0", 200) { cb110_deleted = true; "[\"true\"]" }
      api.delete("/cookbooks/obsolete-cookbook/1.2.0", 200) { cb120_deleted = true; "[\"true\"]" }
      knife.run

      expect(cb100_deleted).to be_truthy
      expect(cb110_deleted).to be_truthy
      expect(cb120_deleted).to be_truthy
    end

    it "asks which version to delete and deletes that when not given the -a flag" do
      cb100_deleted = cb110_deleted = cb120_deleted = nil
      api.delete("/cookbooks/obsolete-cookbook/1.0.0", 200) { cb100_deleted = true; "[\"true\"]" }
      stdin, stdout = StringIO.new, StringIO.new
      allow(knife.ui).to receive(:stdin).and_return(stdin)
      allow(knife.ui).to receive(:stdout).and_return(stdout)
      stdin << "1\n"
      stdin.rewind
      knife.run
      expect(cb100_deleted).to be_truthy
      expect(stdout.string).to match(/Which version\(s\) do you want to delete\?/)
    end

    it "deletes all versions of the cookbook when not given the -a flag and the user chooses to delete all" do
      cb100_deleted = cb110_deleted = cb120_deleted = nil
      api.delete("/cookbooks/obsolete-cookbook/1.0.0", 200) { cb100_deleted = true; "[\"true\"]" }
      api.delete("/cookbooks/obsolete-cookbook/1.1.0", 200) { cb110_deleted = true; "[\"true\"]" }
      api.delete("/cookbooks/obsolete-cookbook/1.2.0", 200) { cb120_deleted = true; "[\"true\"]" }

      stdin, stdout = StringIO.new("4\n"), StringIO.new
      allow(knife.ui).to receive(:stdin).and_return(stdin)
      allow(knife.ui).to receive(:stdout).and_return(stdout)

      knife.run

      expect(cb100_deleted).to be_truthy
      expect(cb110_deleted).to be_truthy
      expect(cb120_deleted).to be_truthy
    end

  end

end
