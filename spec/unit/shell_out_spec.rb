require File.expand_path('../../spec_helper', __FILE__)

describe "Chef::ShellOut deprecation notices" do
  it "logs a warning when initializing a new Chef::ShellOut object" do
    Chef::Log.should_receive(:warn).with("Chef::ShellOut is deprecated, please use Mixlib::ShellOut")
    Chef::Log.should_receive(:warn).with(/Called from\:/)
    Chef::ShellOut.new("pwd")
  end
end

describe "Chef::Exceptions::ShellCommandFailed deprecation notices" do

  it "logs a warning when referencing the constant Chef::Exceptions::ShellCommandFailed" do
    Chef::Log.should_receive(:warn).with("Chef::Exceptions::ShellCommandFailed is deprecated, use Mixlib::ShellOut::ShellCommandFailed")
    Chef::Log.should_receive(:warn).with(/Called from\:/)
    Chef::Exceptions::ShellCommandFailed
  end
end
