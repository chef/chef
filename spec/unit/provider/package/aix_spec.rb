#
# Author:: Deepali Jagtap (deepali.jagtap@clogeny.com)
# Author:: Prabhu Das (prabhu.das@clogeny.com)
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

describe Chef::Provider::Package::Aix do
  let(:package_source) { "/tmp/samba.base" }

  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Package.new("samba.base")
    @new_resource.source(package_source)

    @provider = Chef::Provider::Package::Aix.new(@new_resource, @run_context)
    allow(::File).to receive(:exists?).and_return(true)
  end

  describe "assessing the current package status" do
    before do
      @bffinfo = "/usr/lib/objrepos:samba.base:3.3.12.0::COMMITTED:I:Samba for AIX:
  /etc/objrepos:samba.base:3.3.12.0::COMMITTED:I:Samba for AIX:"

      @empty_status = double("Status", :stdout => "", :exitstatus => 0)
    end

    it "should create a current resource with the name of new_resource" do
      status = double("Status", :stdout => @bffinfo, :exitstatus => 0)
      expect(@provider).to receive(:shell_out).with("installp -L -d /tmp/samba.base", timeout: 900).and_return(status)
      expect(@provider).to receive(:shell_out).with("lslpp -lcq | grep :samba.base", timeout: 900).and_return(@empty_status)
      @provider.load_current_resource
      expect(@provider.current_resource.name).to eq("samba.base")
    end

    it "should set the current resource bff package name to the new resource bff package name" do
      status = double("Status", :stdout => @bffinfo, :exitstatus => 0)
      expect(@provider).to receive(:shell_out).with("installp -L -d /tmp/samba.base", timeout: 900).and_return(status)
      expect(@provider).to receive(:shell_out).with("lslpp -lcq | grep :samba.base", timeout: 900).and_return(@empty_status)
      @provider.load_current_resource
      expect(@provider.current_resource.package_name).to eq("samba.base")
    end

    it "should raise an exception if a source is supplied but not found" do
      allow(@provider).to receive(:shell_out).and_return(@empty_status)
      allow(::File).to receive(:exists?).and_return(false)
      @provider.load_current_resource
      @provider.define_resource_requirements
      expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Package)
    end

    it "should get the source package version from installp if provided" do
      info = <<EOH
wacky.samba.base:wacky.samba.base:1.6.0.25::I:C:::::N:Network Authentication Service Client::::0::
samba.base:samba.base:1.6.0.3::I:C:::::N:Network Authentication Service Client::::0::
EOH
      status = double("Status", :stdout => info, :exitstatus => 0)
      expect(@provider).to receive(:shell_out).with("installp -L -d /tmp/samba.base", timeout: 900).and_return(status)
      expect(@provider).to receive(:shell_out).with("lslpp -lcq | grep :samba.base", timeout: 900).and_return(@empty_status)
      @provider.load_current_resource

      expect(@provider.current_resource.package_name).to eq("samba.base")
      expect(@new_resource.version).to eq("1.6.0.3")
    end

    it "should get the source package version from the highest version available from installp" do
      multi_file_set = <<EOH
samba.base:samba.base.rte:1.6.0.25::I:C:::::N:Network Authentication Service Client::::0::
samba.base:samba.base.rte:1.6.0.3::I:C:::::N:Network Authentication Service Client::::0::
EOH
      status = double("Status", :stdout => multi_file_set, :exitstatus => 0)
      expect(@provider).to receive(:shell_out).with("installp -L -d /tmp/samba.base", timeout: 900).and_return(status)
      expect(@provider).to receive(:shell_out).with("lslpp -lcq | grep :samba.base", timeout: 900).and_return(@empty_status)
      @provider.load_current_resource

      expect(@provider.current_resource.package_name).to eq("samba.base")
      expect(@new_resource.version).to eq("1.6.0.25")
    end

    it "should return the current version installed if found by lslpp" do
      status = double("Status", :stdout => @bffinfo, :exitstatus => 0)
      @stdout = StringIO.new(@bffinfo)
      @stdin, @stderr = StringIO.new, StringIO.new
      expect(@provider).to receive(:shell_out).with("installp -L -d /tmp/samba.base", timeout: 900).and_return(status)
      expect(@provider).to receive(:shell_out).with("lslpp -lcq | grep :samba.base", timeout: 900).and_return(status)
      @provider.load_current_resource
      expect(@provider.current_resource.version).to eq("3.3.12.0")
    end

    context "no package source" do
      let(:package_source) { nil }

      it "should return the current version installed if found by lslpp and when no source" do
        status = double("Status", :stdout => @bffinfo, :exitstatus => 0)
        @stdout = StringIO.new(@bffinfo)
        @stdin, @stderr = StringIO.new, StringIO.new
        expect(@provider).to receive(:shell_out).with("lslpp -lcq | grep :samba.base", timeout: 900).and_return(status)
        @provider.load_current_resource
        expect(@provider.current_resource.version).to eq("3.3.12.0")
      end
    end

    it "should raise an exception if the source is not set but we are installing" do
      status = double("Status", :stdout => "", :exitstatus => 1, :format_for_exception => "")
      @new_resource = Chef::Resource::Package.new("samba.base")
      @provider = Chef::Provider::Package::Aix.new(@new_resource, @run_context)
      allow(@provider).to receive(:shell_out).and_return(status)
      expect { @provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
    end

    it "should raise an exception if installp/lslpp fails to run" do
      status = double(:stdout => "", :exitstatus => -1, :format_for_exception => "")
      allow(@provider).to receive(:shell_out).and_return(status)
      expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Package)
    end

    it "should return a current resource with a nil version if the package is not found" do
      status = double("Status", :stdout => @bffinfo, :exitstatus => 0)
      expect(@provider).to receive(:shell_out).with("installp -L -d /tmp/samba.base", timeout: 900).and_return(status)
      expect(@provider).to receive(:shell_out).with("lslpp -lcq | grep :samba.base", timeout: 900).and_return(@empty_status)
      @provider.load_current_resource
      expect(@provider.current_resource.version).to be_nil
    end

    it "should raise an exception if the source doesn't provide the requested package" do
      wrongbffinfo = "/usr/lib/objrepos:openssl.base:0.9.8.2400::COMMITTED:I:Open Secure Socket Layer:
/etc/objrepos:openssl.base:0.9.8.2400::COMMITTED:I:Open Secure Socket Layer:"
      status = double("Status", :stdout => wrongbffinfo, :exitstatus => 0)
      expect(@provider).to receive(:shell_out).with("installp -L -d /tmp/samba.base", timeout: 900).and_return(status)
      expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Package)
    end

    context "multi fileset packages" do
      let(:src_status) { double("Status", :stdout => src_filesets, :exitstatus => 0) }
      let(:current_status) { double("Status", :stdout => current_filesets, :exitstatus => 0) }
      let(:src_filesets) do
        <<EOH
samba.base:samba.base.rte:1.6.0.3::I:C:::::N:Network Authentication Service Client::::0::
samba.base:samba.base.samples:1.6.0.3::I:C:::::N:Network Authentication Service Client::::0::
EOH
      end
      before do
        allow(@provider).to receive(:shell_out).with("installp -L -d /tmp/samba.base", timeout: 900).and_return(src_status)
        allow(@provider).to receive(:shell_out).with("lslpp -lcq | grep :samba.base", timeout: 900).and_return(current_status)
        @provider.load_current_resource
      end

      context "all filesets are installed but different version" do
        let(:current_filesets) do
          <<EOH
/etc/objrepos:samba.base.rte:1.6.0.2::COMMITTED:I:Samba for AIX:
/etc/objrepos:samba.base.samples:1.6.0.2::COMMITTED:I:Samba for AIX:
EOH
        end

        it "sets current version to the installed versions" do
          expect(@provider.current_resource.version).to eq("1.6.0.2")
        end
      end

      context "all filesets are installed and same version" do
        let(:current_filesets) do
          <<EOH
/etc/objrepos:samba.base.rte:1.6.0.3::COMMITTED:I:Samba for AIX:
/etc/objrepos:samba.base.samples:1.6.0.3::COMMITTED:I:Samba for AIX:
EOH
        end

        it "sets current version to the installed versions" do
          expect(@provider.current_resource.version).to eq("1.6.0.3")
        end
      end

      context "all filesets are installed and some to multiple locations" do
        let(:current_filesets) do
          <<EOH
/etc/objrepos:samba.base.rte:1.6.0.3::COMMITTED:I:Samba for AIX:
/etc/objrepos:samba.base.samples:1.6.0.3::COMMITTED:I:Samba for AIX:
/usr/lib/objrepos:samba.base.samples:1.6.0.3::COMMITTED:I:Samba for AIX:
EOH
        end

        it "sets current version to the installed versions" do
          expect(@provider.current_resource.version).to eq("1.6.0.3")
        end
      end

      context "partial filesets are installed and same version" do
        let(:current_filesets) do
          "/etc/objrepos:samba.base.rte:1.6.0.3::COMMITTED:I:Samba"
        end

        it "does not set current version" do
          expect(@provider.current_resource.version).to be nil
        end
      end

      context "all filesets are installed and mixed versions" do
        let(:current_filesets) do
          <<EOH
/etc/objrepos:samba.base.rte:1.6.0.3::COMMITTED:I:Samba for AIX:
/etc/objrepos:samba.base.samples:1.6.0.2::COMMITTED:I:Samba for AIX:
EOH
        end

        it "does not set current version" do
          expect(@provider.current_resource.version).to be nil
        end
      end
    end
  end

  describe "candidate_version" do
    it "should return the candidate_version variable if already setup" do
      @provider.candidate_version = "3.3.12.0"
      expect(@provider).not_to receive(:shell_out)
      @provider.candidate_version
    end

    it "should lookup the candidate_version if the variable is not already set" do
      bffinfo = "/usr/lib/objrepos:samba.base:3.3.12.0::COMMITTED:I:Samba for AIX:
  /etc/objrepos:samba.base:3.3.12.0::COMMITTED:I:Samba for AIX:"
      status = double(:stdout => bffinfo, :exitstatus => 0)
      expect(@provider).to receive(:shell_out).and_return(status)
      expect(@provider.candidate_version).to eq("3.3.12.0")
    end

    it "should throw and exception if the exitstatus is not 0" do
      @status = double(:stdout => "", :exitstatus => 1, :format_for_exception => "")
      allow(@provider).to receive(:shell_out).and_return(@status)
      expect { @provider.candidate_version }.to raise_error(Chef::Exceptions::Package)
    end

  end

  describe "install and upgrade" do
    it "should run installp -aYF -d with the package source to install" do
      expect(@provider).to receive(:shell_out!).with("installp -aYF -d /tmp/samba.base samba.base", timeout: 900)
      @provider.install_package("samba.base", "3.3.12.0")
    end

    it "should run when the package is a path to install" do
      @new_resource = Chef::Resource::Package.new("/tmp/samba.base")
      @provider = Chef::Provider::Package::Aix.new(@new_resource, @run_context)
      expect(@new_resource.source).to eq("/tmp/samba.base")
      expect(@provider).to receive(:shell_out!).with("installp -aYF -d /tmp/samba.base /tmp/samba.base", timeout: 900)
      @provider.install_package("/tmp/samba.base", "3.3.12.0")
    end

    it "should run installp with -eLogfile option." do
      allow(@new_resource).to receive(:options).and_return("-e/tmp/installp.log")
      expect(@provider).to receive(:shell_out!).with("installp -aYF  -e/tmp/installp.log -d /tmp/samba.base samba.base", timeout: 900)
      @provider.install_package("samba.base", "3.3.12.0")
    end
  end

  describe "remove" do
    it "should run installp -u samba.base to remove the package" do
      expect(@provider).to receive(:shell_out!).with("installp -u samba.base", timeout: 900)
      @provider.remove_package("samba.base", "3.3.12.0")
    end

    it "should run installp -u -e/tmp/installp.log  with options -e/tmp/installp.log" do
      allow(@new_resource).to receive(:options).and_return("-e/tmp/installp.log")
      expect(@provider).to receive(:shell_out!).with("installp -u  -e/tmp/installp.log samba.base", timeout: 900)
      @provider.remove_package("samba.base", "3.3.12.0")
    end

  end
end
