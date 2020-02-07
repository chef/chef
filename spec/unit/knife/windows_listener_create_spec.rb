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
require "chef/knife/windows_listener_create"

describe Chef::Knife::WindowsListenerCreate do
  context "on Windows" do
    before do
      allow(Chef::Platform).to receive(:windows?).and_return(true)
      @listener = Chef::Knife::WindowsListenerCreate.new
    end

    it "creates winrm listener" do
      @listener.config[:hostname] = "host"
      @listener.config[:cert_thumbprint] = "CERT-THUMBPRINT"
      @listener.config[:port] = "5986"
      expect(@listener).to receive(:`).with("winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=\"host\";CertificateThumbprint=\"CERT-THUMBPRINT\";Port=\"5986\"}")
      expect(@listener.ui).to receive(:info).with("WinRM listener created with Port: 5986 and CertificateThumbprint: CERT-THUMBPRINT")
      @listener.run
    end

    it "raise an error on command failure" do
      @listener.config[:hostname] = "host"
      @listener.config[:cert_thumbprint] = "CERT-THUMBPRINT"
      @listener.config[:port] = "5986"
      @listener.config[:basic_auth] = true
      expect(@listener).to receive(:`).with("winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=\"host\";CertificateThumbprint=\"CERT-THUMBPRINT\";Port=\"5986\"}")
      expect($?).to receive(:exitstatus).and_return(100)
      expect(@listener.ui).to receive(:error).with("Error creating WinRM listener. use -VV for more details.")
      expect(@listener.ui).to_not receive(:info).with("WinRM listener created with Port: 5986 and CertificateThumbprint: CERT-THUMBPRINT")
      expect { @listener.run }.to raise_error(SystemExit)
    end

    it "creates winrm listener with cert install option" do
      @listener.config[:hostname] = "host"
      @listener.config[:cert_thumbprint] = "CERT-THUMBPRINT"
      @listener.config[:port] = "5986"
      @listener.config[:cert_install] = true
      allow(@listener).to receive(:get_cert_passphrase).and_return("your-secret!")
      expect(@listener).to receive(:`).with("powershell.exe -Command \" 'your-secret!' | certutil  -importPFX 'true' AT_KEYEXCHANGE\"")
      expect(@listener).to receive(:`).with("powershell.exe -Command \" echo (Get-PfxCertificate true).thumbprint \"")
      expect(@listener.ui).to receive(:info).with("Certificate installed to Certificate Store")
      expect(@listener.ui).to receive(:info).with("Certificate Thumbprint: ")
      allow(@listener).to receive(:puts)
      @listener.run
    end
  end

  context "not on Windows" do
    before do
      allow(Chef::Platform).to receive(:windows?).and_return(false)
      @listener = Chef::Knife::WindowsListenerCreate.new
    end

    it "exits with an error" do
      expect(@listener.ui).to receive(:error)
      expect { @listener.run }.to raise_error(SystemExit)
    end
  end
end
