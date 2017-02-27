#
# Author:: Daniel DeLeo (<dan@chef.io>)
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

describe Chef::FileContentManagement::Deploy::MvUnix do

  let(:content_deployer) { described_class.new }
  let(:target_file_path) { "/etc/my_app.conf" }

  describe "creating the file" do

    it "touches the file to create it" do
      expect(FileUtils).to receive(:touch).with(target_file_path)
      content_deployer.create(target_file_path)
    end
  end

  describe "updating the file" do

    let(:staging_file_path) { "/tmp/random-dir/staging-file.tmp" }

    let(:target_file_mode) { 0644 }
    let(:target_file_stat) do
      double "File::Stat struct for target file",
           :mode => target_file_mode,
           :uid => target_file_uid,
           :gid => target_file_gid
    end

    before do
      expect(File).to receive(:stat).with(target_file_path).and_return(target_file_stat)
      expect(File).to receive(:chmod).with(target_file_mode, staging_file_path).and_return(1)
      expect(FileUtils).to receive(:mv).with(staging_file_path, target_file_path)
    end

    # This context represents the case where:
    # * Chef runs as root
    # * The owner and group of the target file match the owner and group of the
    #   staging file.
    context "when the user has permissions to set file ownership" do

      # For the purposes of this test, the uid/gid can be anything. These
      # values are just chosen because (assuming chef-client's euid == 1001 and
      # egid == 1001), the `chown` call is allowed by the OS. See the
      # description of `EPERM` in `man 2 chown` for reference.
      let(:target_file_uid) { 1001 }
      let(:target_file_gid) { 1001 }

      before do
        expect(File).to receive(:chown).with(target_file_uid, nil, staging_file_path).and_return(1)
        expect(File).to receive(:chown).with(nil, target_file_gid, staging_file_path).and_return(1)
      end

      it "fixes up permissions and moves the file into place" do
        content_deployer.deploy(staging_file_path, target_file_path)
      end

    end

    context "when the user does not have permissions to set file ownership" do

      # The test code does not care what these values are. These values are
      # chosen because they're representitive of the case that chef-client is
      # running as non-root and is managing a file that got ownership set to
      # root somehow. In this example, gid==20 is something like "staff" which
      # the user running chef-client is a member of (but it's not that user's
      # primary group).
      let(:target_file_uid) { 0 }
      let(:target_file_gid) { 20 }

      before do
        expect(File).to receive(:chown).with(target_file_uid, nil, staging_file_path).and_raise(Errno::EPERM)
        expect(File).to receive(:chown).with(nil, target_file_gid, staging_file_path).and_raise(Errno::EPERM)

        expect(Chef::Log).to receive(:warn).with(/^Could not set uid/)
        expect(Chef::Log).to receive(:warn).with(/^Could not set gid/)
      end

      it "fixes up permissions and moves the file into place" do
        content_deployer.deploy(staging_file_path, target_file_path)
      end
    end

  end
end
