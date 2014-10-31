#
# Author:: Steven Danna (<steve@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

describe Chef::Knife::CookbookSiteInstall do
  before(:each) do
    require 'chef/knife/core/cookbook_scm_repo'
    @stdout = StringIO.new
    @knife = Chef::Knife::CookbookSiteInstall.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
    @knife.config = {}
    if Chef::Platform.windows?
      @install_path = 'C:/tmp/chef'
    else
      @install_path = '/var/tmp/chef'
    end
    @knife.config[:cookbook_path] = [ @install_path ]

    @stdout = StringIO.new
    @stderr = StringIO.new
    allow(@knife).to receive(:stderr).and_return(@stdout)
    allow(@knife).to receive(:stdout).and_return(@stdout)

    #Assume all external commands would have succeed. :(
    allow(File).to receive(:unlink)
    allow(File).to receive(:rmtree)
    allow(@knife).to receive(:shell_out!).and_return(true)

    #CookbookSiteDownload Stup
    @downloader = {}
    allow(@knife).to receive(:download_cookbook_to).and_return(@downloader)
    allow(@downloader).to receive(:version) do
      if @knife.name_args.size == 2
        @knife.name_args[1]
      else
        "0.3.0"
      end
    end

    #Stubs for CookbookSCMRepo
    @repo = double(:sanity_check => true, :reset_to_default_state => true,
                 :prepare_to_import => true, :finalize_updates_to => true,
                 :merge_updates_from => true)
    allow(Chef::Knife::CookbookSCMRepo).to receive(:new).and_return(@repo)
  end


  describe "run" do
    it "should return an error if a cookbook name is not provided" do
      @knife.name_args = []
      expect(@knife.ui).to receive(:error).with("Please specify a cookbook to download and install.")
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should return an error if more than two arguments are given" do
      @knife.name_args = ["foo", "bar", "baz"]
      expect(@knife.ui).to receive(:error).with("Installing multiple cookbooks at once is not supported.")
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should return an error if the second argument is not a version" do
      @knife.name_args = ["getting-started", "1pass"]
      expect(@knife.ui).to receive(:error).with("Installing multiple cookbooks at once is not supported.")
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should return an error if the second argument is a four-digit version" do
      @knife.name_args = ["getting-started", "0.0.0.1"]
      expect(@knife.ui).to receive(:error).with("Installing multiple cookbooks at once is not supported.")
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should return an error if the second argument is a one-digit version" do
      @knife.name_args = ["getting-started", "1"]
      expect(@knife.ui).to receive(:error).with("Installing multiple cookbooks at once is not supported.")
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should install the specified version if second argument is a three-digit version" do
      @knife.name_args = ["getting-started", "0.1.0"]
      @knife.config[:no_deps] = true
      upstream_file = File.join(@install_path, "getting-started.tar.gz")
      expect(@knife).to receive(:download_cookbook_to).with(upstream_file)
      expect(@knife).to receive(:extract_cookbook).with(upstream_file, "0.1.0")
      expect(@knife).to receive(:clear_existing_files).with(File.join(@install_path, "getting-started"))
      expect(@repo).to receive(:merge_updates_from).with("getting-started", "0.1.0")
      @knife.run
    end

    it "should install the specified version if second argument is a two-digit version" do
      @knife.name_args = ["getting-started", "0.1"]
      @knife.config[:no_deps] = true
      upstream_file = File.join(@install_path, "getting-started.tar.gz")
      expect(@knife).to receive(:download_cookbook_to).with(upstream_file)
      expect(@knife).to receive(:extract_cookbook).with(upstream_file, "0.1")
      expect(@knife).to receive(:clear_existing_files).with(File.join(@install_path, "getting-started"))
      expect(@repo).to receive(:merge_updates_from).with("getting-started", "0.1")
      @knife.run
    end

    it "should install the latest version if only a cookbook name is given" do
      @knife.name_args = ["getting-started"]
      @knife.config[:no_deps] = true
      upstream_file = File.join(@install_path, "getting-started.tar.gz")
      expect(@knife).to receive(:download_cookbook_to).with(upstream_file)
      expect(@knife).to receive(:extract_cookbook).with(upstream_file, "0.3.0")
      expect(@knife).to receive(:clear_existing_files).with(File.join(@install_path, "getting-started"))
      expect(@repo).to receive(:merge_updates_from).with("getting-started", "0.3.0")
      @knife.run
    end

    it "should not create/reset git branches if use_current_branch is set" do
      @knife.name_args = ["getting-started"]
      @knife.config[:use_current_branch] = true
      @knife.config[:no_deps] = true
      upstream_file = File.join(@install_path, "getting-started.tar.gz")
      expect(@repo).not_to receive(:prepare_to_import)
      expect(@repo).not_to receive(:reset_to_default_state)
      @knife.run
    end

    it "should not raise an error if cookbook_path is a string" do
      @knife.config[:cookbook_path] = @install_path
      @knife.config[:no_deps] = true
      @knife.name_args = ["getting-started"]
      upstream_file = File.join(@install_path, "getting-started.tar.gz")
      expect(@knife).to receive(:download_cookbook_to).with(upstream_file)
      expect(@knife).to receive(:extract_cookbook).with(upstream_file, "0.3.0")
      expect(@knife).to receive(:clear_existing_files).with(File.join(@install_path, "getting-started"))
      expect(@repo).to receive(:merge_updates_from).with("getting-started", "0.3.0")
      expect { @knife.run }.not_to raise_error
    end
  end
end
