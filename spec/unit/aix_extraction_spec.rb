# frozen_string_literal: true

#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#

require "spec_helper"

RSpec.describe "AIX resource extraction" do
  it "does not load AIX-only resources or providers with Chef core" do
    expect(defined?(Chef::Resource::BffPackage)).to be_nil
    expect(defined?(Chef::Resource::User::AixUser)).to be_nil
    expect(defined?(Chef::Provider::Package::Bff)).to be_nil
    expect(defined?(Chef::Provider::Service::Aix)).to be_nil
    expect(defined?(Chef::Provider::Service::AixInit)).to be_nil
    expect(defined?(Chef::Provider::Cron::Aix)).to be_nil
    expect(defined?(Chef::Provider::Group::Aix)).to be_nil
    expect(defined?(Chef::Provider::Ifconfig::Aix)).to be_nil
    expect(defined?(Chef::Provider::Mount::Aix)).to be_nil
    expect(defined?(Chef::Provider::User::Aix)).to be_nil
  end

  it "does not expose the removed premium gate" do
    expect(defined?(Chef::Exceptions::PremiumFeatureRequired)).to be_nil
    expect(defined?(Chef::Mixin::TargetModePremiumGate)).to be_nil
  end
end
