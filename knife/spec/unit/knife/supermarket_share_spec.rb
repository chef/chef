#
# Author:: Stephen Delano (<stephen@chef.io>)
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
require "chef/knife/supermarket_share"
require "chef/cookbook_uploader"
require "chef/knife/core/cookbook_site_streaming_uploader"

describe Chef::Knife::SupermarketShare do

  before(:each) do
    @knife = Chef::Knife::SupermarketShare.new
    # Merge default settings in.
    @knife.merge_configs
    @knife.name_args = %w{cookbook_name AwesomeSausage}

    @cookbook = Chef::CookbookVersion.new("cookbook_name")

    @cookbook_loader = double("Chef::CookbookLoader")
    allow(@cookbook_loader).to receive(:cookbook_exists?).and_return(true)
    allow(@cookbook_loader).to receive(:[]).and_return(@cookbook)
    allow(Chef::CookbookLoader).to receive(:new).and_return(@cookbook_loader)

    @noauth_rest = double(Chef::ServerAPI)
    allow(@knife).to receive(:noauth_rest).and_return(@noauth_rest)

    @cookbook_uploader = Chef::CookbookUploader.new("herpderp", rest: "norest")
    allow(Chef::CookbookUploader).to receive(:new).and_return(@cookbook_uploader)
    allow(@cookbook_uploader).to receive(:validate_cookbooks).and_return(true)
    allow(Chef::Knife::Core::CookbookSiteStreamingUploader).to receive(:create_build_dir).and_return(Dir.mktmpdir)

    allow(@knife).to receive(:shell_out!).and_return(true)
    @stdout = StringIO.new
    @stderr = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
    allow(@knife.ui).to receive(:stderr).and_return(@stderr)
  end

  describe "run" do

    before(:each) do
      allow(@knife).to receive(:do_upload).and_return(true)
      @category_response = {
        "name" => "cookbook_name",
        "category" => "Testing Category",
      }
      @bad_category_response = {
        "error_code" => "NOT_FOUND",
        "error_messages" => [
            "Resource does not exist.",
        ],
      }
    end

    it "should set true to config[:dry_run] as default" do
      expect(@knife.config[:dry_run]).to be_falsey
    end

    it "should should print usage and exit when given no arguments" do
      @knife.name_args = []
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should not fail when given only 1 argument and can determine category" do
      @knife.name_args = ["cookbook_name"]
      expect(@noauth_rest).to receive(:get).with("https://supermarket.chef.io/api/v1/cookbooks/cookbook_name").and_return(@category_response)
      expect(@knife).to receive(:do_upload)
      @knife.run
    end

    it "should use a default category when given only 1 argument and cannot determine category" do
      @knife.name_args = ["cookbook_name"]
      expect(@noauth_rest).to receive(:get).with("https://supermarket.chef.io/api/v1/cookbooks/cookbook_name") { raise Net::HTTPClientException.new("404 Not Found", OpenStruct.new(code: "404")) }
      expect(@knife).to receive(:do_upload)
      expect { @knife.run }.to_not raise_error
    end

    it "should print error and exit when given only 1 argument and Chef::ServerAPI throws an exception" do
      @knife.name_args = ["cookbook_name"]
      expect(@noauth_rest).to receive(:get).with("https://supermarket.chef.io/api/v1/cookbooks/cookbook_name") { raise Errno::ECONNREFUSED, "Connection refused" }
      expect(@knife.ui).to receive(:fatal)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should check if the cookbook exists" do
      expect(@cookbook_loader).to receive(:cookbook_exists?)
      @knife.run
    end

    it "should exit and log to error if the cookbook doesn't exist" do
      allow(@cookbook_loader).to receive(:cookbook_exists?).and_return(false)
      expect(@knife.ui).to receive(:error)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    if File.exist?("/usr/bin/gnutar") || File.exist?("/bin/gnutar")
      it "should use gnutar to make a tarball of the cookbook" do
        expect(@knife).to receive(:shell_out!) do |args|
          expect(args.to_s).to match(/gnutar -czf/)
        end
        @knife.run
      end
    else
      it "should make a tarball of the cookbook" do
        expect(@knife).to receive(:shell_out!) do |args|
          expect(args.to_s).to match(/tar -czf/)
        end
        @knife.run
      end
    end

    it "should exit and log to error when the tarball creation fails" do
      allow(@knife).to receive(:shell_out!).and_raise(Chef::Exceptions::Exec)
      expect(@knife.ui).to receive(:error)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should upload the cookbook and clean up the tarball" do
      expect(@knife).to receive(:do_upload)
      expect(FileUtils).to receive(:rm_rf)
      @knife.run
    end

    context "when the --dry-run flag is specified" do
      before do
        allow(Chef::Knife::Core::CookbookSiteStreamingUploader).to receive(:create_build_dir).and_return("/var/tmp/dummy")
        @knife.config = { dry_run: true }
        @so = instance_double("Mixlib::ShellOut")
        allow(@knife).to receive(:shell_out!).and_return(@so)
        allow(@so).to receive(:stdout).and_return("file")
      end

      it "should list files in the tarball" do
        allow(@knife).to receive(:tar_cmd).and_return("footar")
        expect(@knife).to receive(:shell_out!).with("footar -czf #{@cookbook.name}.tgz #{@cookbook.name}", { cwd: "/var/tmp/dummy" })
        expect(@knife).to receive(:shell_out!).with("footar -tzf #{@cookbook.name}.tgz", { cwd: "/var/tmp/dummy" })
        @knife.run
      end

      it "does not upload the cookbook" do
        expect(@knife).not_to receive(:do_upload)
        @knife.run
      end
    end
  end

  describe "do_upload" do

    before(:each) do
      @upload_response = double("Net::HTTPResponse")
      allow(Chef::Knife::Core::CookbookSiteStreamingUploader).to receive(:post).and_return(@upload_response)

      allow(File).to receive(:open).and_return(true)
    end

    it 'should post the cookbook to "https://supermarket.chef.io"' do
      response_text = Chef::JSONCompat.to_json({ uri: "https://supermarket.chef.io/cookbooks/cookbook_name" })
      allow(@upload_response).to receive(:body).and_return(response_text)
      allow(@upload_response).to receive(:code).and_return(201)
      expect(Chef::Knife::Core::CookbookSiteStreamingUploader).to receive(:post).with(/supermarket\.chef\.io/, anything, anything, anything)
      @knife.run
    end

    it "should alert the user when a version already exists" do
      response_text = Chef::JSONCompat.to_json({ error_messages: ["Version already exists"] })
      allow(@upload_response).to receive(:body).and_return(response_text)
      allow(@upload_response).to receive(:code).and_return(409)
      expect { @knife.run }.to raise_error(SystemExit)
      expect(@stderr.string).to match(/ERROR(.+)cookbook already exists/)
    end

    it "should pass any errors on to the user" do
      response_text = Chef::JSONCompat.to_json({ error_messages: ["You're holding it wrong"] })
      allow(@upload_response).to receive(:body).and_return(response_text)
      allow(@upload_response).to receive(:code).and_return(403)
      expect { @knife.run }.to raise_error(SystemExit)
      expect(@stderr.string).to match("ERROR(.*)You're holding it wrong")
    end

    it "should print the body if no errors are exposed on failure" do
      response_text = Chef::JSONCompat.to_json({ system_error: "Your call was dropped", reason: "There's a map for that" })
      allow(@upload_response).to receive(:body).and_return(response_text)
      allow(@upload_response).to receive(:code).and_return(500)
      expect(@knife.ui).to receive(:error).with(/#{Regexp.escape(response_text)}/) # .ordered
      expect(@knife.ui).to receive(:error).with(/Unknown error/) # .ordered
      expect { @knife.run }.to raise_error(SystemExit)
    end

  end

end
