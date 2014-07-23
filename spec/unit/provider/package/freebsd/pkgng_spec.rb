#
# Authors:: Richard Manyanza (liseki@nyikacraftsmen.com)
# Copyright:: Copyright (c) 2014 Richard Manyanza
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

describe Chef::Provider::Package::Freebsd::Port do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Package.new('zsh')
    @provider = Chef::Provider::Package::Freebsd::Pkgng.new(@new_resource, @run_context)
  end

  describe 'initialization' do
    it 'should create a current resource with the name of the new resource' do
      @provider.current_resource.is_a?(Chef::Resource::Package).should be_true
      @provider.current_resource.name.should == 'zsh'
    end
  end

  describe 'loading current resource' do
    before(:each) do
      @provider.stub(:current_installed_version)
      @provider.stub(:candidate_version)
    end

    it 'should set the package name' do
      @provider.load_current_resource
      @provider.current_resource.package_name.should == 'zsh'
    end

    it 'should set the current version' do
      @provider.should_receive(:current_installed_version).and_return('5.0.2')
      @provider.load_current_resource
      @provider.current_resource.version.should == '5.0.2'
    end

    it 'should set the candidate version' do
      @provider.should_receive(:candidate_version).and_return('5.0.5')
      @provider.load_current_resource
      @provider.instance_variable_get(:"@candidate_version").should == '5.0.5'
    end
  end

  describe 'determining current installed version' do
    before(:each) do
      @provider.stub(:supports_pkgng?)
      @pkg_info = OpenStruct.new(stdout: "zsh-3.1.7\n")
    end

    it 'should query pkg database' do
      @provider.should_receive(:shell_out!).with('pkg info "zsh"', env: nil, returns: [0, 70]).and_return(@pkg_info)
      @provider.current_installed_version.should == '3.1.7'
    end
  end

  describe 'determining candidate version' do
    it 'should query repository' do
      pkg_query = OpenStruct.new(stdout: "5.0.5\n", exitstatus: 0)
      @provider.should_receive(:shell_out!).with("pkg rquery '%v' zsh", env: nil).and_return(pkg_query)
      @provider.candidate_version.should == '5.0.5'
    end

    it 'should query specified repository when given option' do
      @provider.new_resource.options('-r LocalMirror') # This requires LocalMirror repo configuration.
      pkg_query = OpenStruct.new(stdout: "5.0.3\n", exitstatus: 0)
      @provider.should_receive(:shell_out!).with("pkg rquery -r LocalMirror '%v' zsh", env: nil).and_return(pkg_query)
      @provider.candidate_version.should == '5.0.3'
    end

    it 'should return candidate version from file when given a file' do
      @provider.new_resource.source('/nas/pkg/repo/zsh-5.0.1.txz')
      @provider.candidate_version.should == '5.0.1'
    end
  end

  describe 'installing a binary package' do
    before(:each) do
      @install_result = OpenStruct.new(status: true)
    end

    it 'should handle package source from file' do
      @provider.new_resource.source('/nas/pkg/repo/zsh-5.0.1.txz')
      @provider.should_receive(:shell_out!).
        with('pkg add /nas/pkg/repo/zsh-5.0.1.txz', env: { 'LC_ALL' => nil }).
        and_return(@install_result)
      @provider.install_package('zsh', '5.0.1')
    end

    it 'should handle package source over ftp or http' do
      @provider.new_resource.source('http://repo.example.com/zsh-5.0.1.txz')
      @provider.should_receive(:shell_out!).
        with('pkg add http://repo.example.com/zsh-5.0.1.txz', env: { 'LC_ALL' => nil }).
        and_return(@install_result)
      @provider.install_package('zsh', '5.0.1')
    end

    it 'should handle a package name' do
      @provider.should_receive(:shell_out!).
        with('pkg install -y zsh', env: { 'LC_ALL' => nil }).and_return(@install_result)
      @provider.install_package('zsh', '5.0.1')
    end

    it 'should handle a package name with a specified repo' do
      @provider.new_resource.options('-r LocalMirror') # This requires LocalMirror repo configuration.
      @provider.should_receive(:shell_out!).
        with('pkg install -y -r LocalMirror zsh', env: { 'LC_ALL' => nil }).and_return(@install_result)
      @provider.install_package('zsh', '5.0.1')
    end
  end

  describe 'removing a binary package' do
    before(:each) do
      @install_result = OpenStruct.new(status: true)
    end

    it 'should call pkg delete' do
      @provider.should_receive(:shell_out!).
        with('pkg delete -y zsh-5.0.1', env: nil).and_return(@install_result)
      @provider.remove_package('zsh', '5.0.1')
    end

    it 'should not include repo option in pkg delete' do
      @provider.new_resource.options('-r LocalMirror') # This requires LocalMirror repo configuration.
      @provider.should_receive(:shell_out!).
        with('pkg delete -y zsh-5.0.1', env: nil).and_return(@install_result)
      @provider.remove_package('zsh', '5.0.1')
    end
  end
end
