#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
#
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

describe Chef::Provider::User::Solaris do

  subject(:provider) do
    p = described_class.new(@new_resource, @run_context)
    p.current_resource = @current_resource

    # Prevent the useradd-based provider tests from trying to write /etc/shadow
    p.stub!(:write_shadow_file)
    p
  end

  supported_useradd_options = {
    'comment' => "-c",
    'gid' => "-g",
    'uid' => "-u",
    'shell' => "-s"
  }

  include_examples "a useradd-based user provider", supported_useradd_options

  describe "when we want to set a password" do
    before(:each) do
      @node = Chef::Node.new
      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(@node, {}, @events)

      @new_resource = Chef::Resource::User.new("adam", @run_context)
      @current_resource = Chef::Resource::User.new("adam", @run_context)

      @new_resource.password "hocus-pocus"

      # Let these tests run #write_shadow_file
      provider.unstub!(:write_shadow_file)
    end

    it "should use its own shadow file writer to set the password" do
      provider.should_receive(:write_shadow_file)
      provider.stub!(:shell_out!).and_return(true)
      provider.manage_user
    end

    it "should write out a modified version of the password file" do
      password_file = Tempfile.new("shadow")
      password_file.puts "adam:existingpassword:15441::::::"
      password_file.close
      provider.password_file = password_file.path
      provider.stub!(:shell_out!).and_return(true)
      # may not be able to write to /etc for tests...
      temp_file = Tempfile.new("shadow")
      Tempfile.stub!(:new).with("shadow", "/etc").and_return(temp_file)
      @new_resource.password "verysecurepassword"
      provider.manage_user
      ::File.open(password_file.path, "r").read.should =~ /adam:verysecurepassword:/
      password_file.unlink
    end
  end

end
