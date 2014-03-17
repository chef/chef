#
# Author:: Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright (c) 2014 Richard Manyanza.
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

describe Chef::ProviderResolver do
  before(:each) do
    @node = Chef::Node.new
    @provider_resolver = Chef::ProviderResolver.new(@node)
  end

  describe "Initialization" do
    it "should not load providers" do
      @provider_resolver.loaded?.should be_false
    end
  end


  describe "Loading providers" do
  end


  describe "on FreeBSD" do
    before(:each) do
      @node.normal[:platform] = :freebsd
    end

    describe "loading" do
      before(:each) do
        @provider_resolver.load
      end

      it "should load FreeBSD providers" do
        providers = [
          Chef::Provider::User::Pw,
          Chef::Provider::Group::Pw,
          Chef::Provider::Service::Freebsd,
          Chef::Provider::Package::Freebsd,
          Chef::Provider::Cron
        ]

        @provider_resolver.providers.length.should == providers.length
        providers.each do |provider|
          @provider_resolver.providers.include?(provider).should be_true
        end
      end
    end

    describe "resolving" do
      it "should handle user" do
        user = Chef::Resource::User.new('toor')
        @provider_resolver.resolve(user).should == Chef::Provider::User::Pw
      end

      it "should handle group" do
        group = Chef::Resource::Group.new('ops')
        @provider_resolver.resolve(group).should == Chef::Provider::Group::Pw
      end

      it "should handle service" do
        service = Chef::Resource::Service.new('nginx')
        @provider_resolver.resolve(service).should == Chef::Provider::Service::Freebsd
      end

      it "should handle package" do
        package = Chef::Resource::Package.new('zsh')
        @provider_resolver.resolve(package).should == Chef::Provider::Package::Freebsd
      end

      it "should handle cron" do
        cron = Chef::Resource::Cron.new('security_status_report')
        @provider_resolver.resolve(cron).should == Chef::Provider::Cron
      end
    end
  end
end
