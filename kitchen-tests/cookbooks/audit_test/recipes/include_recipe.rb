#
# Cookbook Name:: audit_test
# Recipe:: include_recipe
#
# Copyright (c) 2014 The Authors, All Rights Reserved.

include_recipe "audit_test::default"

controls "another basic control" do
  it "should also pass" do
    arr = [0, 0]
    arr.delete(0)
    expect( arr ).to be_empty
  end
end
