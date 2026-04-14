#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright 2011-2016, Thomas Bishop
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

describe Chef::Knife::ConfigureClient do
  before do
    @knife = Chef::Knife::ConfigureClient.new
    Chef::Config[:chef_server_url] = "https://chef.example.com"
    Chef::Config[:validation_client_name] = "chef-validator"
    Chef::Config[:validation_key] = "/etc/chef/validation.pem"

    @stderr = StringIO.new
    allow(@knife.ui).to receive(:stderr).and_return(@stderr)
  end

  describe "run" do
    it "should print usage and exit when a directory is not provided" do
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal).with(/must provide the directory/)
      expect do
        @knife.run
      end.to raise_error SystemExit
    end

    describe "when specifing a directory" do
      before do
        @knife.name_args = ["/home/bob/.chef"]
        @client_file = StringIO.new
        @validation_file = StringIO.new
        expect(File).to receive(:open).with("/home/bob/.chef/client.rb", "w")
          .and_yield(@client_file)
        expect(File).to receive(:open).with("/home/bob/.chef/validation.pem", "w")
          .and_yield(@validation_file)
        expect(IO).to receive(:read).and_return("foo_bar_baz")
      end

      it "should recursively create the directory" do
        expect(FileUtils).to receive(:mkdir_p).with("/home/bob/.chef")
        @knife.run
      end

      it "should write out the config file" do
        allow(FileUtils).to receive(:mkdir_p)
        @knife.run
        expect(@client_file.string).to match %r{chef_server_url\s+'https\://chef\.example\.com'}
        expect(@client_file.string).to match(/validation_client_name\s+'chef-validator'/)
      end

      it "should write out the validation.pem file" do
        allow(FileUtils).to receive(:mkdir_p)
        @knife.run
        expect(@validation_file.string).to match(/foo_bar_baz/)
      end

      it "should print information on what is being configured" do
        allow(FileUtils).to receive(:mkdir_p)
        @knife.run
        expect(@stderr.string).to match(/creating client configuration/i)
        expect(@stderr.string).to match(/writing client\.rb/i)
        expect(@stderr.string).to match(/writing validation\.pem/i)
      end
    end
  end

end
