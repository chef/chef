#
# Cookbook Name:: audit_test
# Recipe:: default
#
# Copyright (c) 2014 The Authors, All Rights Reserved.

controls "basic control group" do
  control "basic math" do
    it "should pass" do
      expect(2 - 2).to eq(0)
    end
  end
end

controls "control group without top level control" do
  it "should pass" do
    expect(2 - 2).to eq(0)
  end
end

controls "control group with empty control" do
  control "empty"
end

controls "empty control group with block" do
end
