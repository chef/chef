# encoding: UTF-8
#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
require 'webrick'

module AptServer
  def enable_testing_apt_source
    File.open("/etc/apt/sources.list.d/chef-integration-test.list", "w+") do |f|
      f.puts "deb http://localhost:9000/ sid main"
    end
    # Magic to update apt cache for only our repo
    shell_out!("apt-get update " +
               '-o Dir::Etc::sourcelist="sources.list.d/chef-integration-test.list" ' +
               '-o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"')
  end

  def disable_testing_apt_source
    FileUtils.rm("/etc/apt/sources.list.d/chef-integration-test.list")
  rescue Errno::ENOENT
    puts("Attempted to remove integration test from /etc/apt/sources.list.d but it didn't exist")
  end

  def tcp_test_port(hostname, port)
    tcp_socket = TCPSocket.new(hostname, port)
    true
  rescue Errno::ETIMEDOUT
    false
  rescue Errno::ECONNREFUSED
    false
  ensure
    tcp_socket && tcp_socket.close
  end

  def apt_server
    @apt_server ||= WEBrick::HTTPServer.new(
      :Port         => 9000,
      :DocumentRoot => apt_data_dir + "/var/www/apt",
      # Make WEBrick quiet, comment out for debug.
      :Logger       => Logger.new(StringIO.new),
      :AccessLog    => [ StringIO.new, WEBrick::AccessLog::COMMON_LOG_FORMAT ]
    )
  end

  def run_apt_server
    apt_server.start
  end

  def start_apt_server
    @apt_server_thread = Thread.new do
      run_apt_server
    end
    until tcp_test_port("localhost", 9000) do
      if @apt_server_thread.alive?
        sleep 1
      else
        @apt_server_thread.join
        raise "apt server failed to start"
      end
    end
  end

  def stop_apt_server
    apt_server.shutdown
    @apt_server_thread.join
  end

  def apt_data_dir
    File.join(CHEF_SPEC_DATA, "apt")
  end
end

metadata = { :unix_only => true,
  :requires_root => true,
  :provider => {:package => Chef::Provider::Package::Apt},
  :arch => "x86_64" # test packages are 64bit
}

describe Chef::Resource::Package, metadata do
  include Chef::Mixin::ShellOut

  def chef_test_dpkg_installed?
    shell_out("dpkg -l chef-integration-test").status.success?
  end

  def dpkg_should_be_installed(pkg_name)
    shell_out!("dpkg -l #{pkg_name}")
  end


  context "with a remote package source" do

    include AptServer

    before(:all) do
      # Disable mixlib-shellout live streams
      Chef::Log.level = :warn
      start_apt_server
      enable_testing_apt_source
    end

    after(:all) do
      stop_apt_server
      disable_testing_apt_source
      shell_out!("apt-get clean")
    end


    after do
      shell_out!("dpkg -r chef-integration-test")
      shell_out("dpkg --clear-avail")
      shell_out!("apt-get clean")
    end

    let(:node) do
      n = Chef::Node.new
      n.consume_external_attrs(OHAI_SYSTEM.data.dup, {})
      n
    end

    let(:events) do
      Chef::EventDispatch::Dispatcher.new
    end

    # TODO: lots of duplication from client.rb;
    # All of this must be setup for preseed files to get found
    let(:cookbook_collection) do
      cookbook_path = File.join(CHEF_SPEC_DATA, "cookbooks")
      cl = Chef::CookbookLoader.new(cookbook_path)
      cl.load_cookbooks
      Chef::Cookbook::FileVendor.on_create do |manifest|
        Chef::Cookbook::FileSystemFileVendor.new(manifest, cookbook_path)
      end
      Chef::CookbookCollection.new(cl)
    end

    let(:run_context) do
      Chef::RunContext.new(node, cookbook_collection, events)
    end

    def base_resource
      r = Chef::Resource::Package.new("chef-integration-test", run_context)
      # The apt repository in the spec data is not gpg signed, so we need to
      # force apt to accept the package:
      r.options("--force-yes")
      r
    end

    let(:package_resource) do
      base_resource
    end

    # it "results in a usable apt server" do
    #   shell_out!("apt-get install -q -y --force-yes chef-integration-test ", :env => { "DEBIAN_FRONTEND" => "noninteractive" })
    #   shell_out!("dpkg -l chef-integration-test")
    # end

    context "when the package is not yet installed" do
      it "installs the package with action :install" do
        package_resource.run_action(:install)
        shell_out!("dpkg -l chef-integration-test")
        package_resource.should be_updated_by_last_action
      end

      it "installs the package for action :upgrade" do
        package_resource.run_action(:upgrade)
        shell_out!("dpkg -l chef-integration-test")
        package_resource.should be_updated_by_last_action
      end

      it "does nothing for action :remove" do
        package_resource.run_action(:remove)
        shell_out!("dpkg -l chef-integration-test", :returns => [1])
        package_resource.should_not be_updated_by_last_action
      end

      it "does nothing for action :purge" do
        package_resource.run_action(:purge)
        shell_out!("dpkg -l chef-integration-test", :returns => [1])
        package_resource.should_not be_updated_by_last_action
      end

      context "and a not-available package version is specified" do
        let(:package_resource) do
          r = base_resource
          r.version("2.0")
          r
        end

        it "raises a reasonable error for action :install" do
          expect do
            package_resource.run_action(:install)
          end.to raise_error(Chef::Exceptions::Exec)
        end

      end

      describe "when preseeding the install" do

        let(:file_cache_path) { Dir.mktmpdir }

        before do
          @old_config = Chef::Config.configuration.dup
          Chef::Config[:file_cache_path] = file_cache_path
          debconf_reset = 'chef-integration-test chef-integration-test/sample-var string "INVALID"'
          shell_out!("echo #{debconf_reset} |debconf-set-selections")
        end

        after do
          FileUtils.rm_rf(file_cache_path)
          Chef::Config.configuration = @old_config
        end

        context "with a preseed file" do

          let(:package_resource) do
            r = base_resource
            r.cookbook_name = "preseed"
            r.response_file("preseed-file.seed")
            r
          end

          it "preseeds the package, then installs it" do
            package_resource.run_action(:install)
            cmd = shell_out!("debconf-show chef-integration-test")
            cmd.stdout.should include('chef-integration-test/sample-var: "hello world"')
            package_resource.should be_updated_by_last_action
          end

          context "and the preseed file exists and is up-to-date" do

            before do
              # Code here is duplicated from the implementation. Not great, but
              # it should at least fail if the code gets out of sync.
              source = File.join(CHEF_SPEC_DATA, "cookbooks/preseed/files/default/preseed-file.seed")
              file_cache_dir = Chef::FileCache.create_cache_path("preseed/preseed")
              dest = "#{file_cache_dir}/chef-integration-test-1.1-1.seed"
              FileUtils.cp(source, dest)
            end

            it "does not update the package configuration" do
              package_resource.run_action(:install)
              cmd = shell_out!("debconf-show chef-integration-test")
              cmd.stdout.should include('chef-integration-test/sample-var: INVALID')
              package_resource.should be_updated_by_last_action
            end

          end

        end

        context "with a preseed template" do

          let(:package_resource) do
            r = base_resource
            r.cookbook_name = "preseed"
            r.response_file("preseed-template.seed")
            r
          end

          before do
            node.set[:preseed_value] = "FROM TEMPLATE"
          end

          it "preseeds the package, then installs it" do
            package_resource.run_action(:install)
            cmd = shell_out!("debconf-show chef-integration-test")
            cmd.stdout.should include('chef-integration-test/sample-var: "FROM TEMPLATE"')
            package_resource.should be_updated_by_last_action
          end

        end

      end
    end

  end

end


