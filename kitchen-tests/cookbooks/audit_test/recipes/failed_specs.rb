#
# Cookbook Name:: audit_test
# Recipe:: failed_specs
#
# Copyright (c) 2014 The Authors, All Rights Reserved.

control_group "basic control group" do
  control "basic math" do
    # Can not write a good control :(
    it "should pass" do
      expect(2 - 0).to eq(0)
    end
  end
end
