#
# Cookbook Name:: audit_test
# Recipe:: multiple_controls
#
# Copyright (c) 2014 The Authors, All Rights Reserved.

controls "first control" do
  it "should pass" do
    expect(2 - 2).to eq(0)
  end
end

controls "second control" do
  it "should pass" do
    expect(2 - 2).to eq(0)
  end
end
