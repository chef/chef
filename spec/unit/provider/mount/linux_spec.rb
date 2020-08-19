require "spec_helper"
require "ostruct"

describe Chef::Provider::Mount::Linux do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Mount.new("/tmp/foo")
    @new_resource.device      "/dev/sdz1"
    @new_resource.device_type :device
    @new_resource.fstype      "ext3"

    @new_resource.supports remount: false

    @provider = Chef::Provider::Mount::Linux.new(@new_resource, @run_context)

    allow(::File).to receive(:exists?).with("/dev/sdz1").and_return true
    allow(::File).to receive(:exists?).with("/tmp/foo").and_return true
    allow(::File).to receive(:realpath).with("/dev/sdz1").and_return "/dev/sdz1"
    allow(::File).to receive(:realpath).with("/tmp/foo").and_return "/tmp/foo"
  end

  it "should set mounted true if the mount point is found in the mounts list" do
    allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(stdout: "/tmp/foo /dev/sdz1 type ext3 (rw)\n"))
    @provider.load_current_resource
    expect(@provider.current_resource.mounted).to be_truthy
  end

  it "should set mounted false if another mount point beginning with the same path is found in the mounts list" do
    allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(stdout: "/tmp/foobar /dev/sdz1 type ext3 (rw)\n"))
    @provider.load_current_resource
    expect(@provider.current_resource.mounted).to be_falsey
  end

  it "should set mounted true if the symlink target of the device is found in the mounts list" do
    # expand the target path to correct specs on Windows
    target = ::File.expand_path("/dev/mapper/target")

    allow(::File).to receive(:symlink?).with((@new_resource.device).to_s).and_return(true)
    allow(::File).to receive(:readlink).with((@new_resource.device).to_s).and_return(target)

    allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(stdout: "/tmp/foo #{target} type ext3 (rw)\n"))
    @provider.load_current_resource
    expect(@provider.current_resource.mounted).to be_truthy
  end

  it "should set mounted true if the symlink target of the device is relative and is found in the mounts list - CHEF-4957" do
    target = "xsdz1"

    # expand the target path to correct specs on Windows
    absolute_target = ::File.expand_path("/dev/xsdz1")

    allow(::File).to receive(:symlink?).with((@new_resource.device).to_s).and_return(true)
    allow(::File).to receive(:readlink).with((@new_resource.device).to_s).and_return(target)

    allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(stdout: "/tmp/foo #{absolute_target} type ext3 (rw)\n"))
    @provider.load_current_resource
    expect(@provider.current_resource.mounted).to be_truthy
  end

  it "should set mounted true if the mount point is found last in the mounts list" do
    mount = "#{@new_resource.mount_point} /dev/sdy1 type ext3 (rw)\n"
    mount << "#{@new_resource.mount_point} #{@new_resource.device} type ext3 (rw)\n"

    allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(stdout: mount))
    @provider.load_current_resource
    expect(@provider.current_resource.mounted).to be_truthy
  end

  it "should set mounted false if the mount point is not last in the mounts list" do
    mount = "#{@new_resource.device} on #{@new_resource.mount_point} type ext3 (rw)\n"
    mount << "/dev/sdy1 on #{@new_resource.mount_point} type ext3 (rw)\n"

    allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(stdout: mount))
    @provider.load_current_resource
    expect(@provider.current_resource.mounted).to be_falsey
  end

  it "mounted should be false if the mount point is not found in the mounts list" do
    allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(stdout: "/dev/sdy1 on /tmp/foo type ext3 (rw)\n"))
    @provider.load_current_resource
    expect(@provider.current_resource.mounted).to be_falsey
  end

end