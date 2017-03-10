#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "spec_helper"

describe Chef::Provider::File::Content do

  #
  # mock setup
  #

  let(:current_resource) do
    double("Chef::Provider::File::Resource (current)")
  end

  let(:enclosing_directory) do
    canonicalize_path(File.expand_path(File.join(CHEF_SPEC_DATA, "templates")))
  end
  let(:resource_path) do
    canonicalize_path(File.expand_path(File.join(enclosing_directory, "seattle.txt")))
  end

  let(:new_resource) do
    double("Chef::Provider::File::Resource (new)", :name => "seattle.txt", :path => resource_path)
  end

  let(:run_context) do
    double("Chef::RunContext")
  end

  #
  # subject
  #
  let(:content) do
    Chef::Provider::File::Content.new(new_resource, current_resource, run_context)
  end

  describe "when the resource has a content attribute set" do

    before do
      allow(new_resource).to receive(:content).and_return("Do do do do, do do do do, do do do do, do do do do")
    end

    it "returns a tempfile" do
      expect(content.tempfile).to be_a_kind_of(Tempfile)
    end

    it "the tempfile contents should match the resource contents" do
      expect(IO.read(content.tempfile.path)).to eq(new_resource.content)
    end

    it "returns a tempfile in the tempdir when :file_staging_uses_destdir is not set" do
      Chef::Config[:file_staging_uses_destdir] = false
      expect(content.tempfile.path.start_with?(Dir.tmpdir)).to be_truthy
      expect(canonicalize_path(content.tempfile.path).start_with?(enclosing_directory)).to be_falsey
    end

    it "returns a tempfile in the destdir when :file_deployment_uses_destdir is set" do
      Chef::Config[:file_staging_uses_destdir] = true
      expect(content.tempfile.path.start_with?(Dir.tmpdir)).to be_falsey
      expect(canonicalize_path(content.tempfile.path).start_with?(enclosing_directory)).to be_truthy
    end

    context "when creating a tempfiles in destdir fails" do
      let(:enclosing_directory) do
        canonicalize_path("/nonexisting/path")
      end

      it "returns a tempfile in the tempdir when :file_deployment_uses_destdir is set to :auto" do
        Chef::Config[:file_staging_uses_destdir] = :auto
        expect(content.tempfile.path.start_with?(Dir.tmpdir)).to be_truthy
        expect(canonicalize_path(content.tempfile.path).start_with?(enclosing_directory)).to be_falsey
      end

      it "fails when :file_desployment_uses_destdir is set" do
        Chef::Config[:file_staging_uses_destdir] = true
        expect { content.tempfile }.to raise_error(Chef::Exceptions::FileContentStagingError)
      end

      it "returns a tempfile in the tempdir when :file_desployment_uses_destdir is not set" do
        expect(content.tempfile.path.start_with?(Dir.tmpdir)).to be_truthy
        expect(canonicalize_path(content.tempfile.path).start_with?(enclosing_directory)).to be_falsey
      end
    end

  end

  describe "when the resource does not have a content attribute set" do

    before do
      allow(new_resource).to receive(:content).and_return(nil)
    end

    it "should return nil instead of a tempfile" do
      expect(content.tempfile).to be_nil
    end

  end
end
