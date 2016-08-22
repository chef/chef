#
# Author:: Chris Doherty (<cdoherty@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

describe Chef::Resource::WindowsService, :windows_only, :system_windows_service_gem_only, :appveyor_only, :broken => true do
  # Marking as broken. This test is causing appveyor tests to exit with 116.

  include_context "using Win32::Service"

  let(:username) { "service_spec_user" }
  let(:qualified_username) { "#{ENV['COMPUTERNAME']}\\#{username}" }
  let(:password) { "1a2b3c4X!&narf" }

  let(:user_resource) do
    r = Chef::Resource::User::WindowsUser.new(username, run_context)
    r.username(username)
    r.password(password)
    r.comment("temp spec user")
    r
  end

  let(:global_service_file_path) do
    "#{ENV['WINDIR']}\\temp\\#{File.basename(test_service[:service_file_path])}"
  end

  let(:service_params) do

    id = "#{$$}_#{rand(1000)}"

    test_service.merge( {
      run_as_user: qualified_username,
      run_as_password: password,
      service_name: "spec_service_#{id}",
      service_display_name: "windows_service spec #{id}}",
      service_description: "Test service for running the windows_service functional spec.",
      service_file_path: global_service_file_path,
      } )
  end

  let(:manager) do
    Chef::Application::WindowsServiceManager.new(service_params)
  end

  let(:service_resource) do
    r = Chef::Resource::WindowsService.new(service_params[:service_name], run_context)
    [:run_as_user, :run_as_password].each { |prop| r.send(prop, service_params[prop]) }
    r
  end

  before do
    user_resource.run_action(:create)

    # the service executable has to be outside the current user's home
    # directory in order for the logon user to execute it.
    FileUtils.copy_file(test_service[:service_file_path], global_service_file_path)

    # if you don't make the file executable by the service user, you'll get
    # the not-very-helpful "service did not respond fast enough" error.

    # #mode may break in a post-Windows 8.1 release, and have to be replaced
    # with the rights stuff in the file resource.
    file = Chef::Resource::File.new(global_service_file_path, run_context)
    file.mode("0777")

    file.run_action(:create)

    manager.run(%w{--action install})
  end

  after do
    user_resource.run_action(:remove)
    manager.run(%w{--action uninstall})
    File.delete(global_service_file_path)
  end

  describe "logon as a service" do
    it "successfully runs a service as another user" do
      service_resource.run_action(:start)
    end

    it "grants the user the log on as service right" do
      service_resource.run_action(:start)
      expect(Chef::ReservedNames::Win32::Security.get_account_right(qualified_username)).to include("SeServiceLogonRight")
    end
  end
end
