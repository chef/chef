#
# Cookbook Name:: audit_test
# Recipe:: default
#
# Copyright (c) 2014 The Authors, All Rights Reserved.

controls "basic control" do
  control "math" do
    it "should pass" do
      expect(2 - 2).to eq(0)
    end
  end
end
