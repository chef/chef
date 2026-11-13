#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Toomas Pelberg (toomasp@gmx.net)
# Copyright:: Copyright 2009-2016, Bryan McLellan
# Copyright:: Copyright 2010-2016, Toomas Pelberg
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

describe Chef::Provider::Cron::Unix do

  subject(:provider) { Chef::Provider::Cron::Unix.new(new_resource, run_context) }

  let(:username) { "root" }

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) do
    Chef::Resource::Cron.new("cronhole some stuff").tap do |resource|
      resource.user username
      resource.minute "30"
      resource.command "/bin/true"
    end
  end

  let(:status) { double("Process::Status", exitstatus: exitstatus) }
  let(:exitstatus) { 0 }
  let(:shell_out) { double("Mixlib::ShellOut", status: status, stdout: stdout, stderr: stderr) }

  let(:logger) { double("Mixlib::Log::Child").as_null_object }

  it "is a Chef::Provider:Cron" do
    expect(provider).to be_a(Chef::Provider::Cron)
  end

  # Regression test: previously `provides :cron, os: "solaris2"` did not
  # declare `target_mode: true`, so Target Mode runs against a Solaris node
  # raised Chef::Exceptions::ProviderNotFound for the cron resource even
  # though this provider existed.
  describe ".provides" do
    let(:solaris_node) do
      node = Chef::Node.new
      node.automatic[:os] = "solaris2"
      node
    end

    it "is resolved for solaris2 nodes in normal (non-target-mode) runs" do
      allow(Chef::Config).to receive(:target_mode?).and_return(false)
      expect(Chef.provider_handler_map.get(solaris_node, :cron)).to eq(described_class)
    end

    it "is resolved for solaris2 nodes in Target Mode runs" do
      allow(Chef::Config).to receive(:target_mode?).and_return(true)
      expect(Chef.provider_handler_map.get(solaris_node, :cron)).to eq(described_class)
    end
  end

  before do
    allow(run_context).to receive(:logger).and_return(logger)
  end
  describe "read_crontab" do
    let(:stderr) { "" }
    let(:stdout) do
      String.new(<<~CRONTAB)
        0 2 * * * /some/other/command

        # Chef Name: something else
        * 5 * * * /bin/true

        # Another comment
      CRONTAB
    end

    before do
      allow(logger).to receive(:trace)
      allow(shell_out).to receive(:format_for_exception).and_return("formatted command output")
      allow(provider).to receive(:shell_out_compacted).with("/usr/bin/crontab", "-l", user: username).and_return(shell_out)
    end

    it "should call crontab -l with the user" do
      provider.send(:read_crontab)
      expect(provider).to have_received(:shell_out_compacted).with("/usr/bin/crontab", "-l", user: username)
    end

    it "should return the contents of the crontab" do
      crontab = provider.send(:read_crontab)
      expect(crontab).to eq(stdout)
    end

    context "when the user has no crontab" do
      let(:exitstatus) { 1 }

      it "should return nil if the user has no crontab" do
        expect(provider.send(:read_crontab)).to be_nil
      end

      it "logs the crontab output to debug" do
        provider.send(:read_crontab)
        expect(logger).to have_received(:trace).with("formatted command output")
      end
    end

    context "when any other error occurs" do
      let(:exitstatus) { 2 }

      it "should raise an exception if another error occurs" do
        expect do
          provider.send(:read_crontab)
        end.to raise_error(Chef::Exceptions::Cron, "Error determining state of #{new_resource.name}, exit: 2")
      end

      it "logs the crontab output to debug" do
        provider.send(:read_crontab) rescue nil
        expect(logger).to have_received(:trace).with("formatted command output")
      end
    end
  end

  describe "write_crontab" do
    let(:stdout) { "" }
    let(:stderr) { "" }
    # write_crontab uses TargetIO::Dir/File/FileUtils so that in target mode
    # the scratch crontab file is created on the remote target (where
    # shell_out's `crontab` command actually runs) rather than on the local
    # controller. TargetIO falls back to plain ::Dir/::File/::FileUtils when
    # not in target mode, so these specs exercise the real filesystem to
    # confirm the on-disk content and cleanup behavior; RSpec cannot stub
    # TargetIO's method_missing-based dispatch directly.
    before do
      allow(provider).to receive(:shell_out_compacted).and_return(shell_out)
    end

    it "should call crontab for the user" do
      provider.send(:write_crontab, "Foo")
      expect(provider).to have_received(:shell_out_compacted).with("/usr/bin/crontab", anything, user: username)
    end

    it "should call crontab with a file containing the crontab" do
      content = nil
      allow(provider).to receive(:shell_out_compacted) do |*args, **_kwargs|
        content = IO.read(args[1])
        shell_out
      end
      provider.send(:write_crontab, "Foo\n# wibble\n wah!!")
      expect(content).to eq("Foo\n# wibble\n wah!!")
    end

    it "should remove the tempdir used to stage the crontab after writing" do
      tempdir = nil
      allow(provider).to receive(:shell_out_compacted) do |*args, **_kwargs|
        tempdir = ::File.dirname(args[1])
        expect(::Dir.exist?(tempdir)).to be true
        shell_out
      end
      provider.send(:write_crontab, "Foo")
      expect(::Dir.exist?(tempdir)).to be false
    end

    context "when writing the crontab fails" do
      let(:exitstatus) { 1 }
      it "should raise an exception if the command returns non-zero" do
        expect do
          provider.send(:write_crontab, "Foo")
        end.to raise_error(Chef::Exceptions::Cron, /Error updating state of #{new_resource.name}, exit: 1/)
      end

      it "should still remove the tempdir" do
        tempdir = nil
        allow(provider).to receive(:shell_out_compacted) do |*args, **_kwargs|
          tempdir = ::File.dirname(args[1])
          shell_out
        end
        provider.send(:write_crontab, "Foo") rescue nil
        expect(::Dir.exist?(tempdir)).to be false
      end
    end
  end
end
