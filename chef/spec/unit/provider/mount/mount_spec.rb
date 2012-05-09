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

  let(:new_resource_attributes_with_options) do
    { :device => device,
      :device_type => device_type,
      :fstype => fstype,
      :options => mount_options,
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

    it "should not call assert_mountable!  with load_current_resource - CHEF-1565" do
      provider.should_not_receive(:assert_mountable!)
      should_not be_nil
    end

    context 'when filesystem is mounted' do
      it 'should set mounted to true' do
        subject.mounted.should eql true
      end
    end

    context 'when filesystem is not mounted' do
      let(:given) { assume_unmounted and assume_fstab_info }
      let(:assume_unmounted) { provider.stub!(:mounted?).and_return(false) }

      it 'should set mounted to false' do
        subject.mounted.should eql false
      end
    end

    context 'when filesystem is enabled' do
      let(:fstab_info) { { :enabled? => true } }
      it 'should set enabled to true' do
        subject.enabled.should eql true
      end
    end

    context 'when filesystem is not enabled' do
      let(:fstab_info) { { :enabled? => false } }
      it 'should set enabled to false' do
        subject.enabled.should eql false
      end
    end

    it 'should return the current resource' do
      subject.should eql(provider.current_resource)
    end
  end

  describe '#assert_mountable!' do
    let(:should_assert_mount_point_exists) { provider.should_receive(:assert_mount_point_exists!).and_return(true) }

    let(:assume_device_should_exist) { provider.should_receive(:device_should_exist?).and_return(true) }
    let(:should_assert_device_exists) { provider.should_receive(:assert_device_exists!).and_return(true) }
    let(:assume_device_should_not_exist) { provider.should_receive(:device_should_exist?).and_return(false) }
    let(:should_not_assert_device_exists) { provider.should_not_receive(:assert_device_exists!) }

    context 'when device should exist' do

      it 'should assert device exists' do
        assume_device_should_exist
        should_assert_device_exists
        should_assert_mount_point_exists
        provider.assert_mountable!
      end
    end

    context 'when device should not exist' do
      it 'should not assert device exists' do
        assume_device_should_not_exist
        should_not_assert_device_exists
        should_assert_mount_point_exists
        provider.assert_mountable!
      end
    end

    it 'should assert mount point exists' do
        assume_device_should_not_exist
        should_assert_mount_point_exists
        provider.assert_mountable!
    end
  end

  describe '#assert_device_exists!' do
    subject { given; provider.assert_device_exists! }
    let(:given) { assume_new_resource and assume_file_existence }
    let(:assume_file_existence) { ::File.should_receive(:exists?).and_return(device_exists?) }

    context 'when device exists' do
      let(:device_exists?) { true }

      it 'should not raise Chef::Exceptions::Mount' do
        lambda { subject }.should_not raise_error Chef::Exceptions::Mount
      end
    end

    context 'when device does not exists' do
      let(:device_exists?) { false }

      it 'should raise Chef::Exceptions::Mount' do
        lambda { subject }.should raise_error Chef::Exceptions::Mount
      end
    end
  end

  describe '#assert_mount_point_exists!' do
    subject { given; provider.assert_mount_point_exists! }
    let(:given) { assume_new_resource and assume_mount_point_existence }
    let(:assume_mount_point_existence) { ::File.should_receive(:exists?).and_return(device_exists?) }

    context 'when mount point exists' do
      let(:device_exists?) { true }

      it 'should not raise Chef::Exceptions::Mount' do
        lambda { subject }.should_not raise_error Chef::Exceptions::Mount
      end
    end

    context 'when mount point does not exists' do
      let(:device_exists?) { false }

      it 'should raise Chef::Exceptions::Mount' do
        lambda { subject }.should raise_error Chef::Exceptions::Mount
      end
    end
  end

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

    describe "mount_fs" do
      let(:assume_mountable_fs) { provider.should_receive(:assert_mountable!).and_return(true) }
      let(:assume_mount_cmd) { provider.should_receive(:mount_cmd).and_return(mount_cmd) }
      let(:mount_cmd) { mock('mount cmd') }
      let(:cmd) { mount_cmd }

      context 'when filesystem is not mounted' do
        it 'should mount the filesystem' do
          assume_current_resource
          provider.current_resource.mounted false
          assume_mountable_fs
          assume_mount_cmd
          should_shell_out!

          provider.mount_fs
        end
      end

      context 'when filesystem is mounted' do
        it 'should not mount the filesystem' do
          assume_current_resource
          provider.current_resource.mounted true
          provider.should_not_receive(:shell_out!)
          provider.mount_fs
        end
      end
    end

    describe "umount_fs" do
      it "should umount the filesystem if it is mounted" do
        assume_current_resource
        provider.current_resource.mounted true

        provider.should_receive(:shell_out!).with("umount /tmp/foo")
        provider.umount_fs()
      end

      it "should not umount the filesystem if it is not mounted" do
        assume_current_resource
        current_resource.mounted false

        provider.should_not_receive(:shell_out!)
        provider.umount_fs()
      end
    end

    describe "remount_fs" do
      it "should use mount -o remount if remount is supported" do
        assume_current_resource
        assume_new_resource

        new_resource.supports({:remount => true})
        provider.current_resource.mounted true

        provider.should_receive(:shell_out!).with("mount -o remount #{new_resource.mount_point}")
        provider.remount_fs
      end

      it "should umount and mount if remount is not supported" do
        assume_current_resource
        assume_new_resource

        new_resource.supports({:remount => false})
        provider.current_resource.mounted true

        provider.should_receive(:umount_fs)
        provider.should_receive(:sleep).with(1)
        provider.should_receive(:mount_fs)
        provider.remount_fs()
      end

      it "should not try to remount at all if mounted is false" do
        assume_current_resource
        assume_new_resource

        current_resource.mounted false

        provider.should_not_receive(:shell_out!)
        provider.should_not_receive(:umount_fs)
        provider.should_not_receive(:mount_fs)
        provider.remount_fs()
      end
    end

    describe "#enable_fs" do
      let(:fstab) { StringIO.new }

      context 'when fs is not enabled' do
        it "should write fs entry into /etc/fstab" do
          assume_current_resource
          current_resource.enabled false

          ::File.stub!(:open).with("/etc/fstab", "a").and_yield(fstab)

          provider.enable_fs
          fstab.string.should match(%r{^/dev/sdz1\s+/tmp/foo\s+ext3\s+defaults\s+0\s+2\s*$})
        end
      end

      context 'when fs is enabled' do
        it "should not enable if enabled is true and resources match" do
          assume_current_resource
          provider.current_resource.enabled true
          provider.stub!(:mount_options_unchanged?).and_return(true)

          ::File.should_not_receive(:open).with("/etc/fstab", "a")
          provider.enable_fs
        end

        it "should enable if enabled is true and resources do not match" do
          assume_current_resource
          provider.current_resource.enabled true
          provider.stub!(:mount_options_unchanged?).and_return(false)

          provider.should_receive(:disable_fs).and_return(true)
          ::File.stub(:readlines).and_return([])
          ::File.should_receive(:open).once.with("/etc/fstab", "a").and_yield(fstab)

          provider.enable_fs
        end
      end
    end

    describe "#disable_fs" do
      let(:other_mount) { "/dev/sdy1 /tmp/foo  ext3  defaults  1 2\n" }
      let(:target_mount) { "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n" }
      let(:fstab_from_readlines) { [target_mount, other_mount] }

      let(:output) { StringIO.new }
      let(:new_fstab) { output.string }

      it "should disable if enabled is true" do
        assume_current_resource
        provider.current_resource.enabled true

        ::File.stub!(:readlines).with("/etc/fstab").and_return(fstab_from_readlines)
        ::File.stub!(:open).with("/etc/fstab", "w").and_yield(output)

        provider.disable_fs
        new_fstab.should match Regexp.escape(other_mount)
        new_fstab.should_not match Regexp.escape(target_mount)
      end


      context 'with commented lines' do
        let(:commented_mount) { "#/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n" }
        let(:fstab_from_readlines) { [target_mount, other_mount, commented_mount] }

        it "should disable if enabled is true and ignore commented lines" do
          assume_current_resource
          provider.current_resource.enabled true

          ::File.stub!(:readlines).with("/etc/fstab").and_return(fstab_from_readlines)
          ::File.stub!(:open).with("/etc/fstab", "w").and_yield(output)

          provider.disable_fs
          new_fstab.should match Regexp.escape(other_mount)
          new_fstab.should match Regexp.escape(commented_mount)

          new_fstab.should_not match %r{^#{Regexp.escape(target_mount)}}
        end
      end

      context 'when filesystem appears multiple times in fstab' do
        let(:fstab_from_readlines) { [target_mount, other_mount, target_mount] }
        let(:expected_output) { [target_mount, other_mount].join }

        it "should disable only the last entry if enabled is true" do
          assume_current_resource
          provider.current_resource.enabled true

          ::File.stub!(:readlines).with("/etc/fstab").and_return(fstab_from_readlines)
          ::File.stub!(:open).with("/etc/fstab", "w").and_yield(output)

          provider.disable_fs
          new_fstab.should eql expected_output
        end
      end

      it "should not disable if enabled is false" do
        assume_current_resource
        provider.current_resource.enabled false
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

  describe '#mount_options_unchanged?' do
    subject { given; provider.send(:mount_options_unchanged?) }
    let(:given) { assume_new_resource and assume_current_resource and assume_current_resource_state }

    let(:assume_current_resource_state) { current_resource.tap(&with_attributes.call(current_resource_state)) }

    let(:current_resource_state) do
      { :fstype  => current_fstype,
        :options => current_mount_options,
        :dump    => current_dump,
        :pass    => current_pass }
    end

    let(:current_fstype)        { provider.new_resource.fstype }
    let(:current_mount_options) { provider.new_resource.options }
    let(:current_dump)          { provider.new_resource.dump }
    let(:current_pass)          { provider.new_resource.pass }
    let(:token)                 { rand(1000).to_s }

    context 'when mount options are unchanged' do
      it { should be_true }
    end

    context 'when fstype is different' do
      let(:current_fstype) { "#{provider.new_resource.fstype}_#{token}" }
      it { should be_false }
    end

    context 'when mount options are different' do
      let(:current_mount_options) { provider.new_resource.options.dup << token }
      it { should be_false }
    end

    context 'when dump option is different' do
      let(:current_dump) { 1 }
      it { should be_false }
    end

    context 'when pass option is different' do
      let(:current_pass) { 1 }
      it { should be_false }
    end
  end

  describe '#mount_cmd' do
    subject { given; provider.send(:mount_cmd) }
    let(:given) { assume_new_resource }

    let(:mount_point) { '/tmp/foo' }
    let(:fstype) { 'ext3' }
    let(:device) { '/dev/sdz1' }

    context 'without options' do
      it 'should return standard mount command' do
        should eql "mount -t #{fstype} -o defaults #{device} #{mount_point}"
      end
    end

    context 'with empty options' do
      let(:new_resource_attributes) { new_resource_attributes_with_options }
      let(:mount_options) { [] }
      it 'should return standard mount command' do
        should eql "mount -t #{fstype} #{device} #{mount_point}"
      end
    end

    context 'with options' do
      let(:new_resource_attributes) { new_resource_attributes_with_options }
      let(:mount_options) { %w(rw noexec noauto) }
      let(:mount_option_flags) { mount_options.join(',') }

      it "should return mount command with options" do
        should eql "mount -t #{fstype} -o #{mount_option_flags} #{device} #{mount_point}"
      end
    end

    context 'when device is specified by UUID' do
      let(:device_type) { :uuid }
      let(:device) { 'd21afe51-a0fe-4dc6-9152-ac733763ae0a' }
      it "should return mount command with -U flag" do
        should eql "mount -t #{fstype} -o defaults -U #{device} #{mount_point}"
      end
    end

    context 'when device is specified by Label' do
      let(:device_type) { :label }
      let(:device) { 'postgresqldb' }
      it "should return mount command with -L flag" do
        should eql "mount -t #{fstype} -o defaults -L #{device} #{mount_point}"
      end
    end

  end
end
