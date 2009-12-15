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

describe Chef::Knife::CookbookDownload do
  before(:each) do
    @knife = Chef::Knife::CookbookDownload.new
    @knife.config = { }
    @knife.name_args = [ "adam" ]
    @rest = mock(Chef::REST, :null_object => true)
    @metadata = { "metadata" => { "version" => "1.0.1" } }
    @rest.stub!(:get_rest).with("cookbooks/adam").and_return(@metadata)
    @tf = Tempfile.new("easy")
    @rest.stub!(:get_rest).with("cookbooks/adam/_content", true).and_return(@tf)
    @knife.stub!(:rest).and_return(@rest)
    FileUtils.stub!(:cp).and_return(true)
  end

  describe "run" do
    it "should fetch the cookbook metadata" do
      @rest.should_receive(:get_rest).with("cookbooks/adam").and_return(@metadata)
      @knife.run
    end

    it "should not sign on redirect" do
      @rest.should_receive(:sign_on_redirect=).with(false)
      @knife.run
    end

    it "should download the cookbook tarball" do
      @rest.should_receive(:get_rest).with("cookbooks/adam/_content", true).and_return(@tf)
      @knife.run
    end

    it "if the version is given, save to a file with the cookbook name and version" do
      FileUtils.should_receive(:cp).with(@tf.path, File.join(Dir.pwd, "adam-1.0.1.tar.gz"))
      @knife.run
    end

    it "should save to the cookbook name if no version is given" do
      @metadata["metadata"]["version"] = nil
      FileUtils.should_receive(:cp).with(@tf.path, File.join(Dir.pwd, "adam.tar.gz"))
      @knife.run
    end

    describe "with --file" do
      it "should save to the path you passed" do
        @knife.config[:file] = "/tmp/whatsup.tar.gz"
        FileUtils.should_receive(:cp).with(@tf.path, "/tmp/whatsup.tar.gz")
        @knife.run
      end
    end
  end

end

