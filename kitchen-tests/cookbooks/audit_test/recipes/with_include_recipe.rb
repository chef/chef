#
# Cookbook Name:: audit_test
# Recipe:: with_include_recipe
#
# Copyright 2014-2016, The Authors, All Rights Reserved.

include_recipe "audit_test::serverspec_collision"

control_group "basic example" do
  it "should pass" do
    expect(2 - 2).to eq(0)
  end
end

include_recipe "audit_test::serverspec_collision"
include_recipe "audit_test::default"
