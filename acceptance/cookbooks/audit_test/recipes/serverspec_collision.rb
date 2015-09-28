#
# Cookbook Name:: audit_test
# Recipe:: serverspec_collision
#
# Copyright (c) 2014 The Authors, All Rights Reserved.

file "/tmp/audit_test_file" do
  action :create
  content "Welcome to audit mode."
end

control_group "file auditing" do
  describe "test file" do
    it "says welcome" do
      expect(file("/tmp/audit_test_file")).to contain("Welcome")
    end
  end
end

file "/tmp/audit_test_file_2" do
  action :create
  content "Bye to audit mode."
end

control_group "end file auditing" do
  describe "end file" do
    it "says bye" do
      expect(file("/tmp/audit_test_file_2")).to contain("Bye")
    end
  end
end
