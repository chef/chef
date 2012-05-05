#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'

describe Chef::Provider::Mount::Mount do
  include SpecHelpers::Provider

  let(:resource_class) { Chef::Resource::Mount }
  let(:resource_name) { '/tmp/foo' }
  let(:pid) { mock('pid') }

  let(:assume_fstab_info) { provider.stub!(:fstab_info).and_return(fstab_info) }
  let(:assume_mounted) { provider.stub!(:mounted?).and_return(true) }
  let(:assume_symlink) { ::File.stub!(:symlink?).with("#{new_resource.device}").and_return(true) }
  let(:assume_target) { ::File.stub!(:readlink).with("#{new_resource.device}").and_return(symlink_target) }

  let(:fstab_info) { { } }
  let(:new_resource_attributes) do
    { :device => device,
      :device_type => device_type,
      :fstype => fstype,
      :supports => { :remount => false } }
  end

  let(:device) { '/dev/sdz1' }
  let(:device_type) { :device }
  let(:fstype) { 'ext3' }
  let(:symlink_target) { "/dev/mapper/target" }

  describe "#load_current_resource" do
    subject { given; provider.load_current_resource }
    let(:given) { assume_mounted and assume_fstab_info }

    def self.should_load_current_resource_with(attribute)
      it "should load #{attribute} from new resource" do
        subject.send(attribute).should eql(new_resource.send(attribute))
      end
    end

    should_load_current_resource_with :name
    should_load_current_resource_with :mount_point
    should_load_current_resource_with :device


    it "should not call mountable? with load_current_resource - CHEF-1565" do
      provider.should_not_receive(:mountable?)
      should_not be_nil
    end

    it 'should set mounted'

    context 'when filesystem is not mounted' do
      it 'should set mounted to false'
    end

    it 'should set enabled'

    context 'when filesystem is not enabled' do
      it 'should set enabled to false'
    end

    it 'should return the current resource' do
      subject.should eql(provider.current_resource)
    end
  end

  describe '#mountable?' do
    context 'when device should exist' do
      it 'should assert device exists'
    end

    context 'when device should not exist' do
      it 'should not assert device exists'
    end

    it 'should assert mount point exists'
  end

  describe '#assert_device_exists!'
  describe '#assert_mount_point_exists!'

  describe 'mounted?' do
    subject { given; provider.mounted? }
    let(:given) { assume_new_resource and should_shell_out! }
    let(:stdout) { fstab }

    context 'when mount point is found in mounts list' do
      let(:fstab) { '/dev/sdz1 on /tmp/foo' }
      it { should be_true }
    end

    context 'when symlink target of device is found in the mounts list' do
      let(:given) { assume_new_resource and assume_symlink and assume_target and should_shell_out! }
      let(:fstab) { "/dev/mapper/target on /tmp/foo type ext3 (rw)\n" }

      it { should be_true }
    end

    context 'when mount point is found last in the mounts list' do
      let(:fstab) { <<-FSTAB }
/dev/sdy1 on #{new_resource.mount_point} type ext3 (rw)\n
#{new_resource.device} on #{new_resource.mount_point} type ext3 (rw)\n
FSTAB
     it { should be_true }
    end

    context 'when mount point is not found last in the mounts list' do
      let(:fstab) { <<-FSTAB }
#{new_resource.device} on #{new_resource.mount_point} type ext3 (rw)\n
/dev/sdy1 on #{new_resource.mount_point} type ext3 (rw)\n
FSTAB
      it { should be_false }
    end

    context 'when mount point is not found in the mounts list' do
      let(:fstab) { "/dev/sdy1 on /tmp/foo type ext3 (rw)\n" }
      it { should be_false }
    end

    context "with network mounts" do
      let(:fstab) { "#{device}/ on /tmp/foo type #{fstype} (rw)\n" }

      def self.should_ignore_trailing_slash(_device, _fstype)
        context "with #{_fstype} remote mount" do
          let(:device) { _device }
          let(:fstype) { _fstype }
          it("should ignore trailing slash and return true") { should be_true }
        end
      end

      should_ignore_trailing_slash('//nfs:/share', 'nfs')
      should_ignore_trailing_slash('//cifsserver/share', 'cifs')
    end
  end

  describe 'enabled?' do
    subject { given; provider.enabled? }
    let(:given) { assume_new_resource and assume_fstab }
    let(:assume_fstab) { ::File.stub!(:readlines).and_return(fstab) }

    context 'when mount point is last in fstab' do
      let(:fstab) { StringIO.new(<<-FSTAB) }
/dev/sdy1  /tmp/foo  ext3  defaults  1 2
#{new_resource.device} #{new_resource.mount_point}  ext3  defaults  1 2
FSTAB

      it { should be_true }
    end

    context 'when mount point is not last in fstab and mount_point is a substring of another mount' do
      let(:fstab) { StringIO.new(<<-FSTAB) }
#{new_resource.device} #{new_resource.mount_point}  ext3  defaults  1 2
/dev/sdy1  /tmp/foo/bar  ext3  defaults  1 2
FSTAB
      it { should be_true }
    end

    context 'when mount point is not last in fstab' do
      let(:fstab) { StringIO.new(<<-FSTAB) }
#{new_resource.device} #{new_resource.mount_point}  ext3  defaults  1 2
/dev/sdy1 #{new_resource.mount_point}  ext3  defaults  1 2
FSTAB
      it { should be_false }
    end

    context 'when symlink target is in fstab' do
      let(:given) { assume_new_resource and assume_symlink and assume_target and assume_fstab }
      let(:fstab) { StringIO.new "/dev/sdz1  /tmp/foo ext3  defaults  1 2\n" } # Is this actually testing symlink?
      it { should be_true }
    end

    context 'when mount point is not in fstab' do
      let(:fstab) { StringIO.new "/dev/sdy1  #{new_resource.mount_point}  ext3  defaults  1 2\n" }
      it { should be_false }
    end

    context 'when mount point is commented out' do
      let(:fstab) { StringIO.new "\# #{new_resource.device}  #{new_resource.mount_point}  ext3  defaults  1 2\n" }
      it { should be_false }
    end
  end

  context "after the mount's state has been discovered" do
    before do
      current_resource = Chef::Resource::Mount.new("/tmp/foo")
      current_resource.device       "/dev/sdz1"
      current_resource.device_type  :device
      current_resource.fstype       "ext3"

      provider.current_resource = current_resource
    end

    describe "mount_fs" do
      let(:assume_mountable_fs) { provider.should_receive(:mountable?).and_return(true) }

      it "should mount the filesystem if it is not mounted" do
        assume_mountable_fs
        provider.should_receive(:shell_out!).with("mount -t ext3 -o defaults /dev/sdz1 /tmp/foo")
        provider.mount_fs()
      end

      it "should mount the filesystem with options if options were passed" do
        assume_mountable_fs
        options = "rw,noexec,noauto"
        new_resource.options(%w{rw noexec noauto})
        provider.should_receive(:shell_out!).with("mount -t ext3 -o rw,noexec,noauto /dev/sdz1 /tmp/foo")
        provider.mount_fs()
      end

      it "should mount the filesystem specified by uuid" do
        assume_mountable_fs
        new_resource.device "d21afe51-a0fe-4dc6-9152-ac733763ae0a"
        new_resource.device_type :uuid
        stdout_findfs = mock("STDOUT", :first => "/dev/sdz1")
        provider.stub!(:popen4).with("/sbin/findfs UUID=d21afe51-a0fe-4dc6-9152-ac733763ae0a").and_yield(pid,stdin,stdout_findfs,stderr).and_return(status)
        stdout_mock = mock('stdout mock')
        stdout_mock.stub!(:each).and_yield("#{new_resource.device} on #{new_resource.mount_point}")
        provider.should_receive(:shell_out!).with("mount -t #{new_resource.fstype} -o defaults -U #{new_resource.device} #{new_resource.mount_point}").and_return(stdout_mock)
        provider.mount_fs()
      end

      it "should not mount the filesystem if it is mounted" do
        provider.current_resource.stub!(:mounted).and_return(true)
        provider.should_not_receive(:shell_out!)
        provider.mount_fs()
      end

    end

    describe "umount_fs" do
      it "should umount the filesystem if it is mounted" do
        provider.current_resource.mounted(true)
        provider.should_receive(:shell_out!).with("umount /tmp/foo")
        provider.umount_fs()
      end

      it "should not umount the filesystem if it is not mounted" do
        current_resource.mounted(false)
        provider.should_not_receive(:shell_out!)
        provider.umount_fs()
      end
    end

    describe "remount_fs" do
      it "should use mount -o remount if remount is supported" do
        new_resource.supports({:remount => true})
        provider.current_resource.mounted(true)
        provider.should_receive(:shell_out!).with("mount -o remount #{new_resource.mount_point}")
        provider.remount_fs
      end

      it "should umount and mount if remount is not supported" do
        new_resource.supports({:remount => false})
        provider.current_resource.mounted(true)
        provider.should_receive(:umount_fs)
        provider.should_receive(:sleep).with(1)
        provider.should_receive(:mount_fs)
        provider.remount_fs()
      end

      it "should not try to remount at all if mounted is false" do
        current_resource.mounted(false)
        provider.should_not_receive(:shell_out!)
        provider.should_not_receive(:umount_fs)
        provider.should_not_receive(:mount_fs)
        provider.remount_fs()
      end
    end

    describe "when enabling the fs" do
      it "should enable if enabled isn't true" do
        current_resource.enabled(false)

        fstab = StringIO.new
        ::File.stub!(:open).with("/etc/fstab", "a").and_yield(fstab)
        provider.enable_fs
        fstab.string.should match(%r{^/dev/sdz1\s+/tmp/foo\s+ext3\s+defaults\s+0\s+2\s*$})
      end

      it "should not enable if enabled is true and resources match" do
        provider.current_resource.enabled(true)
        provider.current_resource.fstype("ext3")
        provider.current_resource.options(["defaults"])
        provider.current_resource.dump(0)
        provider.current_resource.pass(2)
        ::File.should_not_receive(:open).with("/etc/fstab", "a")

        provider.enable_fs
      end

      it "should enable if enabled is true and resources do not match" do
        provider.current_resource.enabled(true)
        provider.current_resource.fstype("auto")
        provider.current_resource.options(["defaults"])
        provider.current_resource.dump(0)
        provider.current_resource.pass(2)

        provider.should_receive(:disable_fs).and_return(true)

        fstab = StringIO.new
        ::File.stub(:readlines).and_return([])
        ::File.should_receive(:open).once.with("/etc/fstab", "a").and_yield(fstab)

        provider.enable_fs
      end
    end

    describe "when disabling the fs" do
      it "should disable if enabled is true" do
        provider.current_resource.enabled(true)

        other_mount = "/dev/sdy1  /tmp/foo  ext3  defaults  1 2\n"
        this_mount = "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n"

        fstab_read = [this_mount, other_mount]
        ::File.stub!(:readlines).with("/etc/fstab").and_return(fstab_read)
        fstab_write = StringIO.new
        ::File.stub!(:open).with("/etc/fstab", "w").and_yield(fstab_write)

        provider.disable_fs
        fstab_write.string.should match(Regexp.escape(other_mount))
        fstab_write.string.should_not match(Regexp.escape(this_mount))
      end

      it "should disable if enabled is true and ignore commented lines" do
        provider.current_resource.enabled(true)

        fstab_read = [%q{/dev/sdy1 /tmp/foo  ext3  defaults  1 2},
                      %q{/dev/sdz1 /tmp/foo  ext3  defaults  1 2},
                      %q{#/dev/sdz1 /tmp/foo  ext3  defaults  1 2}]
        fstab_write = StringIO.new

        ::File.stub!(:readlines).with("/etc/fstab").and_return(fstab_read)
        ::File.stub!(:open).with("/etc/fstab", "w").and_yield(fstab_write)

        provider.disable_fs
        fstab_write.string.should match(%r{^/dev/sdy1 /tmp/foo  ext3  defaults  1 2$})
        fstab_write.string.should match(%r{^#/dev/sdz1 /tmp/foo  ext3  defaults  1 2$})
        fstab_write.string.should_not match(%r{^/dev/sdz1 /tmp/foo  ext3  defaults  1 2$})
      end

      it "should disable only the last entry if enabled is true" do
        provider.current_resource.stub!(:enabled).and_return(true)
        fstab_read = ["/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n",
                      "/dev/sdy1 /tmp/foo  ext3  defaults  1 2\n",
                      "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n"]

        fstab_write = StringIO.new
        ::File.stub!(:readlines).with("/etc/fstab").and_return(fstab_read)
        ::File.stub!(:open).with("/etc/fstab", "w").and_yield(fstab_write)

        provider.disable_fs
        fstab_write.string.should == "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n/dev/sdy1 /tmp/foo  ext3  defaults  1 2\n"
      end

      it "should not disable if enabled is false" do
        provider.current_resource.stub!(:enabled).and_return(false)

        ::File.stub!(:readlines).with("/etc/fstab").and_return([])
        ::File.should_not_receive(:open)

        provider.disable_fs
      end
    end
  end

  describe '#device_real' do
    subject { given; provider.send(:device_real) }
    let(:given) { assume_new_resource and should_shell_out! }

    let(:should_shell_out!) do
        provider.
          should_receive(:popen4).
          with("/sbin/findfs UUID=#{device}").
          and_yield(pid, stdin, stdout, stderr).and_return(status)
    end

    context 'with :uuid device type' do
      let(:device_type) { :uuid }
      let(:device) { "d21afe51-a0fe-4dc6-9152-ac733763ae0a" }
      let(:real_device) { '/dev/sdz1' }

      let(:stdout) { StringIO.new(real_device) }

      it "should accept device_type :uuid" do
        should_not be_nil
      end

      it 'should find the real device' do
        should eql(real_device)
      end

      context 'when `/sbin/findfs` fails to find device and exits with 1' do
        let(:exitstatus) { 1 }
        let(:real_device) { '' }
        it { should eql('') }
      end
    end

    context 'with :label device type'
  end

  describe '#device_should_exist?' do
    subject { given; provider.device_should_exist? }
    let(:given) { assume_new_resource }
    let(:device) { '/dev/sda1' }

    it { should be_true }

    context "with nfs remote mounts" do
      let(:device) { 'nas.example.com:/home' }
      it { should be_false }
    end

    context "with cifs remote mounts" do
      let(:device) { '//cifsserver/share' }
      it { should be_false }
    end

    context 'with tmpfs fstype' do
      let(:fstype) { 'tmpfs' }
      let(:device) { rand(100000).to_s }
      it { should be_false }
    end

    context 'with fuse fstype' do
      let(:fstype) { 'fuse' }
      let(:device) { rand(100000).to_s }
      it { should be_false }
    end
  end
end
