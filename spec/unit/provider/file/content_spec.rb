#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

describe Chef::Provider::File::Content do

  before(:all) do
    @original_config = Chef::Config.configuration
  end

  after(:all) do
    Chef::Config.configuration.replace(@original_config)
  end

  #
  # mock setup
  #

  let(:current_resource) do
    mock("Chef::Provider::File::Resource (current)")
  end

  let(:enclosing_directory) {
    canonicalize_path(File.expand_path(File.join(CHEF_SPEC_DATA, "templates")))
  }
  let(:resource_path) {
    canonicalize_path(File.expand_path(File.join(enclosing_directory, "seattle.txt")))
  }

  let(:new_resource) do
    mock("Chef::Provider::File::Resource (new)", :name => "seattle.txt", :path => resource_path)
  end

  let(:run_context) do
    mock("Chef::RunContext")
  end

  #
  # subject
  #
  let(:content) do
    Chef::Provider::File::Content.new(new_resource, current_resource, run_context)
  end

  describe "when the resource has a content attribute set" do

    before do
      new_resource.stub!(:content).and_return("Do do do do, do do do do, do do do do, do do do do")
    end

    it "returns a tempfile" do
      content.tempfile.should be_a_kind_of(Tempfile)
    end

    it "the tempfile contents should match the resource contents" do
      IO.read(content.tempfile.path).should == new_resource.content
    end

    it "returns a tempfile in the tempdir when :file_staging_uses_destdir is not set" do
      Chef::Config[:file_staging_uses_destdir] = false
      content.tempfile.path.start_with?(Dir::tmpdir).should be_true
      canonicalize_path(content.tempfile.path).start_with?(enclosing_directory).should be_false
    end

    it "returns a tempfile in the destdir when :file_desployment_uses_destdir is not set" do
      Chef::Config[:file_staging_uses_destdir] = true
      content.tempfile.path.start_with?(Dir::tmpdir).should be_false
      canonicalize_path(content.tempfile.path).start_with?(enclosing_directory).should be_true
    end

  end

  describe "when the resource does not have a content attribute set" do

    before do
      new_resource.stub!(:content).and_return(nil)
    end

    it "should return nil instead of a tempfile" do
      content.tempfile.should be_nil
    end

  end
end

