#
# Author:: Mukta Aphale <mukta.aphale@clogeny.com>
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
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
require "chef/knife/windows_cert_install"

describe Chef::Knife::WindowsCertInstall do
  context "on Windows" do
    before do
      allow(Chef::Platform).to receive(:windows?).and_return(true)
      @certinstall = Chef::Knife::WindowsCertInstall.new
    end

    it "installs certificate" do
      @certinstall.name_args = ["test-path"]
      @certinstall.config[:cert_passphrase] = "your-secret!"
      allow(Chef::Platform).to receive(:windows?).and_return(true)
      expect(@certinstall).to receive(:`).with("powershell.exe -Command \" 'your-secret!' | certutil -importPFX 'test-path' AT_KEYEXCHANGE\"")
      expect(@certinstall.ui).to receive(:info).with("Certificate added to Certificate Store")
      expect(@certinstall.ui).to receive(:info).with("Adding certificate to the Windows Certificate Store...")
      @certinstall.run
    end
  end

  context "not on Windows" do
    before do
      allow(Chef::Platform).to receive(:windows?).and_return(false)
      @certinstall = Chef::Knife::WindowsCertInstall.new
    end

    it "exits with an error" do
      expect(@listener.ui).to receive(:error)
      expect { @listener.run }.to raise_error(SystemExit)
    end
  end
end
