#
# Cookbook Name:: audit_test
# Recipe:: error_orphan_control
#
# Copyright (c) 2014 The Authors, All Rights Reserved.

control_group "basic control group" do
  it "should pass" do
    expect(2 - 2).to eq(0)
  end
end

control "orphan control"
