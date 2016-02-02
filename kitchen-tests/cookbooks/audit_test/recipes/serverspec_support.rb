#
# Cookbook Name:: audit_test
# Recipe:: serverspec_support
#
# Copyright 2014-2016, The Authors, All Rights Reserved.

file "/tmp/audit_test_file" do
  action :create
  content "Welcome to audit mode."
end

# package "curl" do
#   action :install
# end

control_group "serverspec helpers with types" do
  control "file helper" do
    it "says welcome" do
      expect(file("/tmp/audit_test_file")).to contain("Welcome")
    end
  end

  control service("com.apple.CoreRAID") do
    it { is_expected.to be_enabled }
    it { is_expected.not_to be_running }
  end

  # describe "package helper" do
  #   it "works" do
  #     expect(package("curl")).to be_installed
  #   end
  # end

  control package("postgresql") do
    it { is_expected.to_not be_installed }
  end
end
