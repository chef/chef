#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright 2016, Chef Software Inc.
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

describe Chef::FileContentManagement::Tempfile do
  let(:resource) {
    r = Chef::Resource::File.new("new_file")
    r.path "/foo/bar/new_file"
    r
  }

  subject { described_class.new(resource) }

  describe "#tempfile_basename" do
    it "should return a dotfile", :unix_only do
      expect(subject.send(:tempfile_basename)).to eql(".chef-new_file")
    end

    it "should return a file", :windows_only do
      expect(subject.send(:tempfile_basename)).to eql("chef-new_file")
    end
  end

  describe "#tempfile_dirnames" do

    it "should select a temp dir" do
      Chef::Config[:file_staging_uses_destdir] = false
      expect(Dir).to receive(:tmpdir).and_return("/tmp/dir")
      expect(subject.send(:tempfile_dirnames)).to eql(%w{ /tmp/dir })
    end

    it "should select the destdir" do
      Chef::Config[:file_staging_uses_destdir] = true
      expect(subject.send(:tempfile_dirnames)).to eql(%w{ /foo/bar })
    end

    it "should select the destdir and a temp dir" do
      Chef::Config[:file_staging_uses_destdir] = :auto
      expect(Dir).to receive(:tmpdir).and_return("/tmp/dir")
      expect(subject.send(:tempfile_dirnames)).to eql(%w{ /foo/bar /tmp/dir })
    end
  end

  describe "#tempfile_open" do
    let(:tempfile) { instance_double("Tempfile") }
    let(:tempname) { windows? ? "chef-new_file" : ".chef-new_file" }

    before do
      Chef::Config[:file_staging_uses_destdir] = :auto
      allow(tempfile).to receive(:binmode).and_return(true)
    end

    it "should create a temporary file" do
      expect(subject.send(:tempfile_open)).to be_a(Tempfile)
    end

    it "should pick the destdir preferrentially" do
      expect(Tempfile).to receive(:open).with(tempname, "/foo/bar").and_return(tempfile)
      subject.send(:tempfile_open)
    end

    it "should use ENV['TMP'] otherwise" do
      expect(Dir).to receive(:tmpdir).and_return("/tmp/dir")
      expect(Tempfile).to receive(:open).with(tempname, "/foo/bar").and_raise(SystemCallError, "foo")
      expect(Tempfile).to receive(:open).with(tempname, "/tmp/dir").and_return(tempfile)
      subject.send(:tempfile_open)
    end
  end
end
