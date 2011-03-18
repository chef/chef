#
# Author:: Nuo Yan (<nuo@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
require 'tmpdir'

describe Chef::Knife::CookbookCreate do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::CookbookCreate.new
    @knife.config = {}
    @knife.name_args = ["foobar"]
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
  end

  describe "run" do

    it "should create a new cookbook with default values to copyright name, email and apache license if those are not supplied" do
      @dir = Dir.tmpdir
      @knife.config = {:cookbook_path => @dir}
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "YOUR_COMPANY_NAME", "none")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "YOUR_COMPANY_NAME", "YOUR_EMAIL", "none")
      @knife.run
    end

    it "should create a new cookbook with specified company name in the copyright section if one is specified" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "none")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "YOUR_EMAIL", "none")
      @knife.run
    end

    it "should create a new cookbook with specified copyright name and email if they are specified" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "none")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "none")
      @knife.run
    end

    it "should create a new cookbook with specified copyright name and email and license information (true) if they are specified" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com",
        :cookbook_license => "apachev2"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "apachev2")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "apachev2")
      @knife.run
    end

    it "should create a new cookbook with specified copyright name and email and license information (false) if they are specified" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com",
        :cookbook_license => false
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "none")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "none")
      @knife.run
    end

    it "should create a new cookbook with specified copyright name and email and license information ('false' as string) if they are specified" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com",
        :cookbook_license => "false"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "none")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "none")
      @knife.run
    end

    it "should allow specifying a gpl2 license" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com",
        :cookbook_license => "gplv2"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "gplv2")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "gplv2")
      @knife.run
    end

    it "should allow specifying a gplv3 license" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com",
        :cookbook_license => "gplv3"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "gplv3")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "gplv3")
      @knife.run
    end

    it "should allow specifying the mit license" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com",
        :cookbook_license => "mit"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "mit")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "mit")
      @knife.run
    end

    it "should throw argument error if the cookbooks path is not specified in the config file nor supplied via parameter" do
      @dir = Dir.tmpdir
      Chef::Config[:cookbook_path]=nil
      lambda{@knife.run}.should raise_error(ArgumentError)
    end

  end
end
