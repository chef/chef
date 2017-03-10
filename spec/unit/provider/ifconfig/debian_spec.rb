#
# Author:: Xabier de Zuazo (xabier@onddo.com)
# Copyright:: Copyright 2013-2016, Onddo Labs, SL.
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
require "chef/exceptions"

describe Chef::Provider::Ifconfig::Debian do

  let(:run_context) do
    node = Chef::Node.new
    cookbook_collection = Chef::CookbookCollection.new([])
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, cookbook_collection, events)
  end

  let(:new_resource) do
    new_resource = Chef::Resource::Ifconfig.new("10.0.0.1", run_context)
    new_resource.mask "255.255.254.0"
    new_resource.metric "1"
    new_resource.mtu "1500"
    new_resource.device "eth0"
    new_resource
  end

  let(:current_resource) { Chef::Resource::Ifconfig.new("10.0.0.1", run_context) }

  let(:provider) do
    status = double("Status", exitstatus: 0)
    provider = Chef::Provider::Ifconfig::Debian.new(new_resource, run_context)
    provider.instance_variable_set("@status", status)
    provider.current_resource = current_resource
    allow(provider).to receive(:load_current_resource)
    allow(provider).to receive(:shell_out!)
    provider
  end

  let(:config_filename_ifaces) { "/etc/network/interfaces" }

  let(:config_filename_ifcfg) { "/etc/network/interfaces.d/ifcfg-#{new_resource.device}" }

  describe "generate_config" do

    context "when writing a file" do
      let(:tempfile) { Tempfile.new("rspec-chef-ifconfig-debian") }

      let(:tempdir_path) { Dir.mktmpdir("rspec-chef-ifconfig-debian-dir") }

      let(:config_filename_ifcfg) { "#{tempdir_path}/ifcfg-#{new_resource.device}" }

      before do
        stub_const("Chef::Provider::Ifconfig::Debian::INTERFACES_FILE", tempfile.path)
        stub_const("Chef::Provider::Ifconfig::Debian::INTERFACES_DOT_D_DIR", tempdir_path)
      end

      it "should write a network-script" do
        provider.run_action(:add)
        expect(File.read(config_filename_ifcfg)).to match(/^iface eth0 inet static\s*$/)
        expect(File.read(config_filename_ifcfg)).to match(/^\s+address 10\.0\.0\.1\s*$/)
        expect(File.read(config_filename_ifcfg)).to match(/^\s+netmask 255\.255\.254\.0\s*$/)
      end

      context "when the interface_dot_d directory does not exist" do
        before do
          FileUtils.rmdir tempdir_path
          expect(File.exist?(tempdir_path)).to be_falsey
        end

        it "should create the /etc/network/interfaces.d directory" do
          provider.run_action(:add)
          expect(File.exist?(tempdir_path)).to be_truthy
          expect(File.directory?(tempdir_path)).to be_truthy
        end

        it "should mark the resource as updated" do
          provider.run_action(:add)
          expect(new_resource.updated_by_last_action?).to be_truthy
        end
      end

      context "when the interface_dot_d directory exists" do
        before do
          expect(File.exist?(tempdir_path)).to be_truthy
        end

        it "should still mark the resource as updated (we still write a file to it)" do
          provider.run_action(:add)
          expect(new_resource.updated_by_last_action?).to be_truthy
        end
      end
    end

    context "when the file is up-to-date" do
      let(:tempfile) { Tempfile.new("rspec-chef-ifconfig-debian") }

      let(:tempdir_path) { Dir.mktmpdir("rspec-chef-ifconfig-debian-dir") }

      let(:config_filename_ifcfg) { "#{tempdir_path}/ifcfg-#{new_resource.device}" }

      before do
        stub_const("Chef::Provider::Ifconfig::Debian::INTERFACES_FILE", tempfile.path)
        stub_const("Chef::Provider::Ifconfig::Debian::INTERFACES_DOT_D_DIR", tempdir_path)
        expect(File.exist?(tempdir_path)).to be_truthy # since the file exists, the enclosing dir must also exist
      end

      context "when the /etc/network/interfaces file has the source line" do
        let(:expected_string) do
          <<-EOF
a line
source #{tempdir_path}/*
another line
EOF
        end

        before do
          tempfile.write(expected_string)
          tempfile.close

          expect(provider).not_to receive(:converge_by).with(/modifying #{tempfile.path} to source #{tempdir_path}/)
        end

        it "should preserve all the contents" do
          provider.run_action(:add)
          expect(IO.read(tempfile.path)).to eq(expected_string)
        end

      end

      context "when the /etc/network/interfaces file does not have the source line" do
        let(:expected_string) do
          <<-EOF
a line
another line
source #{tempdir_path}/*
EOF
        end

        before do
          tempfile.write("a line\nanother line\n")
          tempfile.close

          allow(provider).to receive(:converge_by).and_call_original
          expect(provider).to receive(:converge_by).with(/modifying #{tempfile.path} to source #{tempdir_path}/).and_call_original
        end

        it "should preserve the original contents and add the source line" do
          provider.run_action(:add)
          expect(IO.read(tempfile.path)).to eq(expected_string)
        end

        it "should mark the resource as updated" do
          provider.run_action(:add)
          expect(new_resource.updated_by_last_action?).to be_truthy
        end
      end
    end

    describe "when running under why run" do

      before do
        Chef::Config[:why_run] = true
      end

      after do
        Chef::Config[:why_run] = false
      end

      context "when writing a file" do
        let(:config_file_ifcfg) { StringIO.new }

        let(:tempfile) { Tempfile.new("rspec-chef-ifconfig-debian") }

        let(:tempdir_path) { Dir.mktmpdir("rspec-chef-ifconfig-debian-dir") }

        let(:config_filename_ifcfg) { "#{tempdir_path}/ifcfg-#{new_resource.device}" }

        before do
          stub_const("Chef::Provider::Ifconfig::Debian::INTERFACES_FILE", tempfile.path)
          stub_const("Chef::Provider::Ifconfig::Debian::INTERFACES_DOT_D_DIR", tempdir_path)
          expect(File).not_to receive(:new).with(config_filename_ifcfg, "w")
        end

        it "should write a network-script" do
          provider.run_action(:add)
          expect(config_file_ifcfg.string).not_to match(/^iface eth0 inet static\s*$/)
          expect(config_file_ifcfg.string).not_to match(/^\s+address 10\.0\.0\.1\s*$/)
          expect(config_file_ifcfg.string).not_to match(/^\s+netmask 255\.255\.254\.0\s*$/)
        end

        context "when the interface_dot_d directory does not exist" do
          before do
            FileUtils.rmdir tempdir_path
            expect(File.exist?(tempdir_path)).to be_falsey
          end

          it "should not create the /etc/network/interfaces.d directory" do
            provider.run_action(:add)
            expect(File.exist?(tempdir_path)).not_to be_truthy
          end

          it "should mark the resource as updated" do
            provider.run_action(:add)
            expect(new_resource.updated_by_last_action?).to be_truthy
          end
        end

        context "when the interface_dot_d directory exists" do
          before do
            expect(File.exist?(tempdir_path)).to be_truthy
          end

          it "should still mark the resource as updated (we still write a file to it)" do
            provider.run_action(:add)
            expect(new_resource.updated_by_last_action?).to be_truthy
          end
        end
      end

      context "when the file is up-to-date" do
        let(:tempfile) { Tempfile.new("rspec-chef-ifconfig-debian") }

        let(:tempdir_path) { Dir.mktmpdir("rspec-chef-ifconfig-debian-dir") }

        let(:config_filename_ifcfg) { "#{tempdir_path}/ifcfg-#{new_resource.device}" }

        before do
          stub_const("Chef::Provider::Ifconfig::Debian::INTERFACES_FILE", tempfile.path)
          stub_const("Chef::Provider::Ifconfig::Debian::INTERFACES_DOT_D_DIR", tempdir_path)
          expect(File).not_to receive(:new).with(config_filename_ifcfg, "w")
          expect(File.exist?(tempdir_path)).to be_truthy # since the file exists, the enclosing dir must also exist
        end

        context "when the /etc/network/interfaces file has the source line" do
          let(:expected_string) do
            <<-EOF
a line
source #{tempdir_path}/*
another line
            EOF
          end

          before do
            tempfile.write(expected_string)
            tempfile.close
          end

          it "should preserve all the contents" do
            provider.run_action(:add)
            expect(IO.read(tempfile.path)).to eq(expected_string)
          end

        end

        context "when the /etc/network/interfaces file does not have the source line" do
          let(:expected_string) do
            <<-EOF
a line
another line
source #{tempdir_path}/*
            EOF
          end

          before do
            tempfile.write("a line\nanother line\n")
            tempfile.close
          end

          it "should preserve the original contents and not add the source line" do
            provider.run_action(:add)
            expect(IO.read(tempfile.path)).to eq("a line\nanother line\n")
          end

          it "should mark the resource as updated" do
            provider.run_action(:add)
            expect(new_resource.updated_by_last_action?).to be_truthy
          end
        end
      end
    end
  end

  describe "delete_config for action_delete" do

    let(:tempfile) { Tempfile.new("rspec-chef-ifconfig-debian") }

    let(:tempdir_path) { Dir.mktmpdir("rspec-chef-ifconfig-debian-dir") }

    let(:config_filename_ifcfg) { "#{tempdir_path}/ifcfg-#{new_resource.device}" }

    before do
      stub_const("Chef::Provider::Ifconfig::Debian::INTERFACES_FILE", tempfile.path)
      stub_const("Chef::Provider::Ifconfig::Debian::INTERFACES_DOT_D_DIR", tempdir_path)
      File.open(config_filename_ifcfg, "w") do |fh|
        fh.write "arbitrary text\n"
        fh.close
      end
    end

    after do
      Dir.rmdir(tempdir_path)
    end

    it "should delete network-script if it exists" do
      current_resource.device new_resource.device

      # belt and suspenders testing?
      expect_any_instance_of(Chef::Util::Backup).to receive(:do_backup).and_call_original

      # internal implementation detail of Ifconfig.
      expect_any_instance_of(Chef::Provider::File).to receive(:action_delete).and_call_original

      expect(File.exist?(config_filename_ifcfg)).to be_truthy
      provider.run_action(:delete)
      expect(File.exist?(config_filename_ifcfg)).to be_falsey
    end
  end

end
