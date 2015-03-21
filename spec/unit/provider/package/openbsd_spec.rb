#
# Author:: Scott Bonds (scott@ggr.com)
# Copyright:: Copyright (c) 2014 Scott Bonds
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
require 'ostruct'

describe Chef::Provider::Package::Openbsd do

  let(:node) do
    node = Chef::Node.new
    node.default['kernel'] = {'name' => 'OpenBSD', 'release' => '5.5', 'machine' => 'amd64'}
    node
  end

  let (:provider) do
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::Package::Openbsd.new(new_resource, run_context)
  end

  let(:new_resource) { Chef::Resource::Package.new(name)}

  before(:each) do
    ENV['PKG_PATH'] = nil
  end

  describe "install a package" do
    let(:name) { 'ihavetoes' }
    let(:version) {'0.0'}

    context 'when not already installed' do
      before do
        allow(provider).to receive(:shell_out!).with("pkg_info -e \"#{name}->0\"", anything()).and_return(instance_double('shellout', :stdout => ''))
      end

      context 'when there is a single candidate' do

        context 'when installing from source' do
          it 'should run the installation command' do
            pending('Installing from source is not supported yet')
            # This is a consequence of load_current_resource being called before define_resource_requirements
            # It can be deleted once an implementation is provided
            allow(provider).to receive(:shell_out!).with("pkg_info -I \"#{name}\"", anything()).and_return(
              instance_double('shellout', :stdout => "#{name}-#{version}\n"))
            new_resource.source('/some/path/on/disk.tgz')
            provider.run_action(:install)
          end
        end

        context 'when source is not provided' do
          it 'should run the installation command' do
            expect(provider).to receive(:shell_out!).with("pkg_info -I \"#{name}\"", anything()).and_return(
              instance_double('shellout', :stdout => "#{name}-#{version}\n"))
            expect(provider).to receive(:shell_out!).with(
              "pkg_add -r #{name}-#{version}",
              {:env => {"PKG_PATH" => "http://ftp.OpenBSD.org/pub/OpenBSD/5.5/packages/amd64/"}}
            ) {OpenStruct.new :status => true}
            provider.run_action(:install)
          end
        end
      end

      context 'when there are multiple candidates' do
        let(:flavor_a) { 'flavora' }
        let(:flavor_b) { 'flavorb' }

        context 'if no version is specified' do
          it 'should raise an exception' do
            expect(provider).to receive(:shell_out!).with("pkg_info -I \"#{name}\"", anything()).and_return(
              instance_double('shellout', :stdout => "#{name}-#{version}-#{flavor_a}\n#{name}-#{version}-#{flavor_b}\n"))
            expect { provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package, /multiple matching candidates/)
          end
        end

        context 'if a flavor is specified' do

          let(:flavor) { 'flavora' }
          let(:package_name) {'ihavetoes' }
          let(:name) { "#{package_name}--#{flavor}" }

          context 'if no version is specified' do
            it 'should run the installation command' do
              expect(provider).to receive(:shell_out!).with("pkg_info -e \"#{package_name}->0\"", anything()).and_return(instance_double('shellout', :stdout => ''))
              expect(provider).to receive(:shell_out!).with("pkg_info -I \"#{name}\"", anything()).and_return(
                instance_double('shellout', :stdout => "#{name}-#{version}-#{flavor}\n"))
              expect(provider).to receive(:shell_out!).with(
                "pkg_add -r #{name}-#{version}-#{flavor}",
                {:env => {"PKG_PATH" => "http://ftp.OpenBSD.org/pub/OpenBSD/5.5/packages/amd64/"}}
              ) {OpenStruct.new :status => true}
              provider.run_action(:install)
            end
          end

          context 'if a version is specified' do
            it 'runs the installation command' do
              pending('Specifying both a version and flavor is not supported')
              new_resource.version(version)
              allow(provider).to receive(:shell_out!).with(/pkg_info -e/, anything()).and_return(instance_double('shellout', :stdout => ''))
              allow(provider).to receive(:candidate_version).and_return("#{package_name}-#{version}-#{flavor}")
              provider.run_action(:install)
            end
          end
        end

        context 'if a version is specified' do
          it 'should use the flavor from the version' do
            expect(provider).to receive(:shell_out!).with("pkg_info -I \"#{name}-#{version}-#{flavor_b}\"", anything()).and_return(
              instance_double('shellout', :stdout => "#{name}-#{version}-#{flavor_a}\n"))

            new_resource.version("#{version}-#{flavor_b}")
            expect(provider).to receive(:shell_out!).with(
              "pkg_add -r #{name}-#{version}-#{flavor_b}",
              {:env => {"PKG_PATH" => "http://ftp.OpenBSD.org/pub/OpenBSD/5.5/packages/amd64/"}}
            ) {OpenStruct.new :status => true}
            provider.run_action(:install)
          end
        end
      end
    end
  end

  describe "delete a package" do
    before do
      @name = 'ihavetoes'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
    end
    it "should run the command to delete the installed package" do
      expect(@provider).to receive(:shell_out!).with(
        "pkg_delete #{@name}", :env=>nil
      ) {OpenStruct.new :status => true}
      @provider.remove_package(@name, nil)
    end
  end

end

