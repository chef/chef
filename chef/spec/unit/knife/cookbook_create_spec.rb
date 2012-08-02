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

require 'spec_helper'
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

    # Fixes CHEF-2579
    it "should expand the path of the cookbook directory" do
      File.should_receive(:expand_path).with("~/tmp/monkeypants")
      @knife.config = {:cookbook_path => "~/tmp/monkeypants"}
      @knife.stub!(:create_cookbook)
      @knife.stub!(:create_readme)
      @knife.stub!(:create_changelog)
      @knife.stub!(:create_metadata)
      @knife.run
    end

    it "should create a new cookbook with default values to copyright name, email, readme format and license if those are not supplied" do
      @dir = Dir.tmpdir
      @knife.config = {:cookbook_path => @dir}
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "YOUR_COMPANY_NAME", "none")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "md")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "YOUR_COMPANY_NAME", "YOUR_EMAIL", "none", "md")
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
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "md")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "YOUR_EMAIL", "none", "md")
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
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "md")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "none", "md")
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
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "md")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "apachev2", "md")
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
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "md")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "none", "md")
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
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "md")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "none", "md")
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
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "md")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "gplv2", "md")
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
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "md")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "gplv3", "md")
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
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "md")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "mit", "md")
      @knife.run
    end

    it "should allow specifying the rdoc readme format" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com",
        :cookbook_license => "mit",
        :readme_format => "rdoc"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "mit")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "rdoc")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "mit", "rdoc")
      @knife.run
    end

    it "should allow specifying the mkd readme format" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com",
        :cookbook_license => "mit",
        :readme_format => "mkd"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "mit")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "mkd")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "mit", "mkd")
      @knife.run
    end

    it "should allow specifying the txt readme format" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com",
        :cookbook_license => "mit",
        :readme_format => "txt"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "mit")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "txt")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "mit", "txt")
      @knife.run
    end

    it "should allow specifying an arbitrary readme format" do
      @dir = Dir.tmpdir
      @knife.config = {
        :cookbook_path => @dir,
        :cookbook_copyright => "Opscode, Inc",
        :cookbook_email => "nuo@opscode.com",
        :cookbook_license => "mit",
        :readme_format => "foo"
      }
      @knife.name_args=["foobar"]
      @knife.should_receive(:create_cookbook).with(@dir, @knife.name_args.first, "Opscode, Inc", "mit")
      @knife.should_receive(:create_readme).with(@dir, @knife.name_args.first, "foo")
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.should_receive(:create_metadata).with(@dir, @knife.name_args.first, "Opscode, Inc", "nuo@opscode.com", "mit", "foo")
      @knife.run
    end

    it "should create a CHANGELOG file" do
      @dir = Dir.tmpdir
      @knife.should_receive(:create_changelog).with(@dir, @knife.name_args.first)
      @knife.run
    end

    context "when the cookbooks path is not specified in the config file nor supplied via parameter" do
      before do
        @old_cookbook_path = Chef::Config[:cookbook_path]
        Chef::Config[:cookbook_path] = nil
      end

      it "should throw an argument error" do
        @dir = Dir.tmpdir
        lambda{@knife.run}.should raise_error(ArgumentError)
      end

      after do
        Chef::Config[:cookbook_path] = @old_cookbook_path
      end
    end

  end
end
