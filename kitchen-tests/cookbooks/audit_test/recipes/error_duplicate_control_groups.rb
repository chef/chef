#
# Cookbook Name:: audit_test
# Recipe:: error_duplicate_control_groups
#
# Copyright 2014-2016, The Authors, All Rights Reserved.

control_group "basic control group" do
  it "should pass" do
    expect(2 - 2).to eq(0)
  end
end

control_group "basic control group" do
  it "should pass" do
    expect(2 - 2).to eq(0)
  end
end
