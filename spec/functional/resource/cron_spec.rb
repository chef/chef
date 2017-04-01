# encoding: UTF-8
#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright 2013-2017, Chef Software Inc.
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
require "functional/resource/base"
require "chef/mixin/shell_out"

describe Chef::Resource::Cron, :requires_root, :unix_only do

  include Chef::Mixin::ShellOut

  # Platform specific validation routines.
  def cron_should_exists(cron_name, command)
    case ohai[:platform]
    when "aix", "solaris", "opensolaris", "solaris2", "omnios"
      expect(shell_out("crontab -l #{new_resource.user} | grep \"#{cron_name}\"").exitstatus).to eq(0)
      expect(shell_out("crontab -l #{new_resource.user} | grep \"#{cron_name}\"").stdout.lines.to_a.size).to eq(1)
      expect(shell_out("crontab -l #{new_resource.user} | grep \"#{command}\"").exitstatus).to eq(0)
      expect(shell_out("crontab -l #{new_resource.user} | grep \"#{command}\"").stdout.lines.to_a.size).to eq(1)
    else
      expect(shell_out("crontab -l -u #{new_resource.user} | grep \"#{cron_name}\"").exitstatus).to eq(0)
      expect(shell_out("crontab -l #{new_resource.user} | grep \"#{cron_name}\"").stdout.lines.to_a.size).to eq(0)
      expect(shell_out("crontab -l -u #{new_resource.user} | grep \"#{command}\"").exitstatus).to eq(0)
      expect(shell_out("crontab -l #{new_resource.user} | grep \"#{command}\"").stdout.lines.to_a.size).to eq(0)
    end
  end

  def cron_should_not_exists(cron_name)
    case ohai[:platform]
    when "aix", "solaris", "opensolaris", "solaris2", "omnios"
      expect(shell_out("crontab -l #{new_resource.user} | grep \"#{cron_name}\"").exitstatus).to eq(1)
      expect(shell_out("crontab -l #{new_resource.user} | grep \"#{new_resource.command}\"").stdout.lines.to_a.size).to eq(0)
    else
      expect(shell_out("crontab -l -u #{new_resource.user} | grep \"#{cron_name}\"").exitstatus).to eq(1)
      expect(shell_out("crontab -l -u #{new_resource.user} | grep \"#{new_resource.command}\"").stdout.lines.to_a.size).to eq(0)
    end
  end

  # Actual tests
  let(:new_resource) do
    new_resource = Chef::Resource::Cron.new("Chef functional test cron", run_context)
    new_resource.user  "root"
    # @hourly is not supported on solaris, aix
    if ohai[:platform] == "solaris" || ohai[:platform] == "solaris2" || ohai[:platform] == "aix"
      new_resource.minute "0 * * * *"
    else
      new_resource.minute "@hourly"
    end
    new_resource.hour ""
    new_resource.day ""
    new_resource.month ""
    new_resource.weekday ""
    new_resource.command "/bin/true"
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  describe "create action" do
    after do
      new_resource.run_action(:delete)
    end

    it "should create a crontab entry" do
      new_resource.run_action(:create)
      cron_should_exists(new_resource.name, new_resource.command)
    end

    it "should create exactly one crontab entry" do
      5.times { new_resource.run_action(:create) }
      cron_should_exists(new_resource.name, new_resource.command)
    end
  end

  describe "delete action" do
    before do
      new_resource.run_action(:create)
    end

    it "should delete a crontab entry" do
      # Note that test cron is created by previous test
      new_resource.run_action(:delete)

      cron_should_not_exists(new_resource.name)
    end
  end

  exclude_solaris = %w{solaris opensolaris solaris2 omnios}.include?(ohai[:platform])
  describe "create action with various attributes", :external => exclude_solaris do
    def create_and_validate_with_attribute(resource, attribute, value)
      if ohai[:platform] == "aix"
        expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::Cron, /Aix cron entry does not support environment variables. Please set them in script and use script in cron./)
      else
        resource.run_action(:create)
        # Verify if the cron is created successfully
        cron_attribute_should_exists(resource.name, attribute, value)
      end
    end

    def cron_attribute_should_exists(cron_name, attribute, value)
      return if %w{aix solaris}.include?(ohai[:platform])
      # Test if the attribute exists on newly created cron
      cron_should_exists(cron_name, "")
      expect(shell_out("crontab -l -u #{new_resource.user} | grep '#{attribute.upcase}=\"#{value}\"'").exitstatus).to eq(0)
    end

    after do
      new_resource.run_action(:delete)
    end

    it "should create a crontab entry for mailto attribute" do
      new_resource.mailto "cheftest@example.com"
      create_and_validate_with_attribute(new_resource, "mailto", "cheftest@example.com")
    end

    it "should create a crontab entry for path attribute" do
      new_resource.path "/usr/local/bin"
      create_and_validate_with_attribute(new_resource, "path", "/usr/local/bin")
    end

    it "should create a crontab entry for shell attribute" do
      new_resource.shell "/bin/bash"
      create_and_validate_with_attribute(new_resource, "shell", "/bin/bash")
    end

    it "should create a crontab entry for home attribute" do
      new_resource.home "/home/opscode"
      create_and_validate_with_attribute(new_resource, "home", "/home/opscode")
    end

    %i{ home mailto path shell }.each do |attr|
      it "supports an empty string for #{attr} attribute" do
        new_resource.send(attr, "")
        create_and_validate_with_attribute(new_resource, attr.to_s, "")
      end
    end
  end

  describe "negative tests for create action" do
    after do
      new_resource.run_action(:delete)
    end

    def cron_create_should_raise_exception
      expect { new_resource.run_action(:create) }.to raise_error(Chef::Exceptions::Cron)
      cron_should_not_exists(new_resource.name)
    end

    it "should not create cron with invalid minute" do
      new_resource.minute "invalid"
      cron_create_should_raise_exception
    end

    it "should not create cron with invalid user" do
      new_resource.user "1-really-really-invalid-user-name"
      cron_create_should_raise_exception
    end

  end
end
