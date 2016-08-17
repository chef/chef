#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

require "spec_helper"
require "ostruct"

# Do not run these tests on windows because some path handling
# code is not implemented to handle windows paths.

describe Chef::Provider::Mount::Solaris, :unix_only do
  let(:node) { Chef::Node.new }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:device_type) { :device }

  let(:fstype) { "ufs" }

  let(:device) { "/dev/dsk/c0t2d0s7" }

  let(:fsck_device) { "/dev/rdsk/c0t2d0s7" }

  let(:mountpoint) { "/mnt/foo" }

  let(:options) { nil }

  let(:new_resource) do
    new_resource = Chef::Resource::Mount.new(mountpoint)
    new_resource.device      device
    new_resource.device_type device_type
    new_resource.fsck_device fsck_device
    new_resource.fstype      fstype
    new_resource.options     options
    new_resource.supports :remount => false
    new_resource
  end

  let(:provider) do
    Chef::Provider::Mount::Solaris.new(new_resource, run_context)
  end

  let(:vfstab_file_contents) do
    <<-EOF.gsub /^\s*/, ""
    #device         device          mount           FS      fsck    mount   mount
    #to mount       to fsck         point           type    pass    at boot options
    #
    fd      -       /dev/fd fd      -       no      -
    /proc   -       /proc   proc    -       no      -
    # swap
    /dev/dsk/c0t0d0s1       -       -       swap    -       no      -
    # root
    /dev/dsk/c0t0d0s0       /dev/rdsk/c0t0d0s0      /       ufs     1       no      -
    # tmpfs
    swap    -       /tmp    tmpfs   -       yes     -
    # nfs
    cartman:/share2         -                       /cartman        nfs     -       yes     rw,soft
    # ufs
    /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
    EOF
  end

  let(:vfstab_file) do
    t = Tempfile.new("rspec-vfstab")
    t.write(vfstab_file_contents)
    t.close
    t
  end

  let(:mount_output) do
    <<-EOF.gsub /^\s*/, ""
    /dev/dsk/c0t0d0s0 on / type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200000 on Tue Jul 31 22:34:46 2012
    /dev/dsk/c0t2d0s7 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
    EOF
  end

  before do
    stub_const("Chef::Provider::Mount::Solaris::VFSTAB", vfstab_file.path )
    allow(provider).to receive(:shell_out!).with("mount -v").and_return(OpenStruct.new(:stdout => mount_output))
    allow(File).to receive(:symlink?).with(device).and_return(false)
    allow(File).to receive(:exist?).and_call_original # Tempfile.open on ruby 1.8.7 calls File.exist?
    allow(File).to receive(:exist?).with(device).and_return(true)
    allow(File).to receive(:exist?).with(mountpoint).and_return(true)
    expect(File).to_not receive(:exists?)
  end

  describe "#define_resource_requirements" do
    before do
      # we're not testing the actual actions so stub them all out
      [:mount_fs, :umount_fs, :remount_fs, :enable_fs, :disable_fs].each { |m| allow(provider).to receive(m) }
    end

    it "run_action(:mount) should raise an error if the device does not exist" do
      allow(File).to receive(:exist?).with(device).and_return(false)
      expect { provider.run_action(:mount) }.to raise_error(Chef::Exceptions::Mount)
    end

    it "run_action(:remount) should raise an error if the device does not exist" do
      allow(File).to receive(:exist?).with(device).and_return(false)
      expect { provider.run_action(:remount) }.to raise_error(Chef::Exceptions::Mount)
    end

    it "run_action(:mount) should raise an error if the mountpoint does not exist" do
      allow(File).to receive(:exist?).with(mountpoint).and_return false
      expect { provider.run_action(:mount) }.to raise_error(Chef::Exceptions::Mount)
    end

    it "run_action(:remount) should raise an error if the mountpoint does not exist" do
      allow(File).to receive(:exist?).with(mountpoint).and_return false
      expect { provider.run_action(:remount) }.to raise_error(Chef::Exceptions::Mount)
    end

    %w{tmpfs nfs ctfs proc mntfs objfs sharefs fd smbfs vxfs}.each do |ft|
      context "when the device has a fstype of #{ft}" do
        let(:fstype) { ft }
        let(:fsck_device) { "-" }
        let(:device) { "something_that_is_not_a_file" }

        before do
          expect(File).to_not receive(:exist?).with(device)
        end

        it "run_action(:mount) should not raise an error" do
          expect { provider.run_action(:mount) }.to_not raise_error
        end

        it "run_action(:remount) should not raise an error" do
          expect { provider.run_action(:remount) }.to_not raise_error
        end
      end
    end

  end

  describe "#load_current_resource" do
    context "when loading a normal UFS filesystem with mount at boot" do

      before do
        provider.load_current_resource
      end

      it "should create a current_resource of type Chef::Resource::Mount" do
        expect(provider.current_resource).to be_a(Chef::Resource::Mount)
      end

      it "should set the name on the current_resource" do
        expect(provider.current_resource.name).to eq(mountpoint)
      end

      it "should set the mount_point on the current_resource" do
        expect(provider.current_resource.mount_point).to eq(mountpoint)
      end

      it "should set the device on the current_resource" do
        expect(provider.current_resource.device).to eq(device)
      end

      it "should set the fsck_device on the current_resource" do
        expect(provider.current_resource.fsck_device).to eq(fsck_device)
      end

      it "should set the device_type on the current_resource" do
        expect(provider.current_resource.device_type).to eq(device_type)
      end

      it "should set the mounted status on the current_resource" do
        expect(provider.current_resource.mounted).to be_truthy
      end

      it "should set the enabled status on the current_resource" do
        expect(provider.current_resource.enabled).to be_truthy
      end

      it "should set the fstype field on the current_resource" do
        expect(provider.current_resource.fstype).to eql("ufs")
      end

      it "should set the options field on the current_resource" do
        expect(provider.current_resource.options).to eql(["-"])
      end

      it "should set the pass field on the current_resource" do
        expect(provider.current_resource.pass).to eql(2)
      end

      it "should not throw an exception when the device does not exist - CHEF-1565" do
        allow(File).to receive(:exist?).with(device).and_return(false)
        expect { provider.load_current_resource }.to_not raise_error
      end

      it "should not throw an exception when the mount point does not exist" do
        allow(File).to receive(:exist?).with(mountpoint).and_return false
        expect { provider.load_current_resource }.to_not raise_error
      end
    end
  end

  describe "#load_current_resource" do
    context "when loading a normal UFS filesystem with noauto, don't mount at boot" do

      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        #device         device          mount           FS      fsck    mount   mount
        #to mount       to fsck         point           type    pass    at boot options
        #
        fd      -       /dev/fd fd      -       no      -
        /proc   -       /proc   proc    -       no      -
        # swap
        /dev/dsk/c0t0d0s1       -       -       swap    -       no      -
        # root
        /dev/dsk/c0t0d0s0       /dev/rdsk/c0t0d0s0      /       ufs     1       no      -
        # tmpfs
        swap    -       /tmp    tmpfs   -       yes     -
        # nfs
        cartman:/share2         -                       /cartman        nfs     -       yes     rw,soft
        # ufs
        /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       no     -
        EOF
      end

      before do
        provider.load_current_resource
      end

      it "should set the options field on the current_resource" do
        expect(provider.current_resource.options).to eql(["-", "noauto"])
      end
    end

    context "when the device is an smbfs mount" do
      let(:mount_output) do
        <<-EOF.gsub /^\s*/, ""
        //solarsystem/tmp on /mnt type smbfs read/write/setuid/devices/dev=5080000 on Tue Mar 29 11:40:18 2011
        EOF
      end
      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        //WORKGROUP;username:password@host/share    -   /mountpoint smbfs   -   no  fileperms=0777,dirperms=0777
        EOF
      end

      let(:fsck_device) { "-" }

      it "should work at some point in the future" do
        skip "SMBFS mounts on solaris look like they will need some future code work and more investigation"
      end
    end

    context "when the device is an NFS mount" do
      let(:mount_output) do
        <<-EOF.gsub /^\s*/, ""
        cartman:/share2 on /cartman type nfs rsize=32768,wsize=32768,NFSv4,dev=4000004 on Tue Mar 29 11:40:18 2011
        EOF
      end

      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        cartman:/share2         -                       /cartman        nfs     -       yes     rw,soft
        EOF
      end

      let(:fsck_device) { "-" }

      let(:fstype) { "nfs" }

      let(:device) { "cartman:/share2" }

      let(:mountpoint) { "/cartman" }

      before do
        provider.load_current_resource
      end

      it "should set the name on the current_resource" do
        expect(provider.current_resource.name).to eq(mountpoint)
      end

      it "should set the mount_point on the current_resource" do
        expect(provider.current_resource.mount_point).to eq(mountpoint)
      end

      it "should set the device on the current_resource" do
        expect(provider.current_resource.device).to eq(device)
      end

      it "should set the device_type on the current_resource" do
        expect(provider.current_resource.device_type).to eq(device_type)
      end

      it "should set the mounted status on the current_resource" do
        expect(provider.current_resource.mounted).to be_truthy
      end

      it "should set the enabled status on the current_resource" do
        expect(provider.current_resource.enabled).to be_truthy
      end

      it "should set the fstype field on the current_resource" do
        expect(provider.current_resource.fstype).to eql("nfs")
      end

      it "should set the options field on the current_resource" do
        expect(provider.current_resource.options).to eql(%w{rw soft})
      end

      it "should set the pass field on the current_resource" do
        # is this correct or should it be nil?
        #
        # vfstab man page says.
        # "A -  is used to indicate no entry in a field."
        # 0 and - could mean different things for some file systems
        expect(provider.current_resource.pass).to eql(0)
      end

    end

    context "when the device is symlink" do

      let(:target) { "/dev/mapper/target" }

      let(:mount_output) do
        <<-EOF.gsub /^\s*/, ""
        #{target} on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        EOF
      end

      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        #{target}       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        EOF
      end

      before do
        expect(File).to receive(:symlink?).with(device).at_least(:once).and_return(true)
        expect(File).to receive(:readlink).with(device).at_least(:once).and_return(target)

        provider.load_current_resource()
      end

      it "should set mounted true if the symlink target of the device is found in the mounts list" do
        expect(provider.current_resource.mounted).to be_truthy
      end

      it "should set enabled true if the symlink target of the device is found in the vfstab" do
        expect(provider.current_resource.enabled).to be_truthy
      end

      it "should have the correct mount options" do
        expect(provider.current_resource.options).to eql(["-"])
      end
    end

    context "when the device is a relative symlink" do
      let(:target) { "foo" }

      let(:absolute_target) { File.expand_path(target, File.dirname(device)) }

      let(:mount_output) do
        <<-EOF.gsub /^\s*/, ""
        #{absolute_target} on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        EOF
      end

      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        #{absolute_target}       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        EOF
      end

      before do
        expect(File).to receive(:symlink?).with(device).at_least(:once).and_return(true)
        expect(File).to receive(:readlink).with(device).at_least(:once).and_return(target)

        provider.load_current_resource()
      end

      it "should set mounted true if the symlink target of the device is found in the mounts list" do
        expect(provider.current_resource.mounted).to be_truthy
      end

      it "should set enabled true if the symlink target of the device is found in the vfstab" do
        expect(provider.current_resource.enabled).to be_truthy
      end

      it "should have the correct mount options" do
        expect(provider.current_resource.options).to eql(["-"])
      end
    end

    context "when the matching mount point is last in the mounts list" do
      let(:mount_output) do
        <<-EOF.gsub /^\s*/, ""
        /dev/dsk/c0t0d0s0 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200000 on Tue Jul 31 22:34:46 2012
        /dev/dsk/c0t2d0s7 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        EOF
      end
      it "should set mounted true" do
        provider.load_current_resource()
        expect(provider.current_resource.mounted).to be_truthy
      end
    end

    context "when the matching mount point is not last in the mounts list" do
      let(:mount_output) do
        <<-EOF.gsub /^\s*/, ""
        /dev/dsk/c0t2d0s7 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        /dev/dsk/c0t0d0s0 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200000 on Tue Jul 31 22:34:46 2012
        EOF
      end
      it "should set mounted false" do
        provider.load_current_resource()
        expect(provider.current_resource.mounted).to be_falsey
      end
    end

    context "when the matching mount point is not in the mounts list (mountpoint wrong)" do
      let(:mount_output) do
        <<-EOF.gsub /^\s*/, ""
        /dev/dsk/c0t2d0s7 on /mnt/foob type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        EOF
      end
      it "should set mounted false" do
        provider.load_current_resource()
        expect(provider.current_resource.mounted).to be_falsey
      end
    end

    context "when the matching mount point is not in the mounts list (raw device wrong)" do
      let(:mount_output) do
        <<-EOF.gsub /^\s*/, ""
        /dev/dsk/c0t2d0s72 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        EOF
      end
      it "should set mounted false" do
        provider.load_current_resource()
        expect(provider.current_resource.mounted).to be_falsey
      end
    end

    context "when the mount point is last in fstab" do
      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        /dev/dsk/c0t2d0s72       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        EOF
      end

      it "should set enabled to true" do
        provider.load_current_resource
        expect(provider.current_resource.enabled).to be_truthy
      end
    end

    context "when the mount point is not last in fstab and is a substring of another mount" do
      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        /dev/dsk/c0t2d0s72       /dev/rdsk/c0t2d0s7      /mnt/foo/bar            ufs     2       yes     -
        EOF
      end

      it "should set enabled to true" do
        provider.load_current_resource
        expect(provider.current_resource.enabled).to be_truthy
      end
    end

    context "when the mount point is not last in fstab" do
      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        /dev/dsk/c0t2d0s72       /dev/rdsk/c0t2d0s72      /mnt/foo            ufs     2       yes     -
        EOF
      end

      it "should set enabled to false" do
        provider.load_current_resource
        expect(provider.current_resource.enabled).to be_falsey
      end
    end

    context "when the mount point is not in fstab, but the mountpoint is a substring of one that is" do
      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foob            ufs     2       yes     -
        EOF
      end

      it "should set enabled to false" do
        provider.load_current_resource
        expect(provider.current_resource.enabled).to be_falsey
      end
    end

    context "when the mount point is not in fstab, but the device is a substring of one that is" do
      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        /dev/dsk/c0t2d0s72       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        EOF
      end

      it "should set enabled to false" do
        provider.load_current_resource
        expect(provider.current_resource.enabled).to be_falsey
      end
    end

    context "when the mountpoint line is commented out" do
      let(:vfstab_file_contents) do
        <<-EOF.gsub /^\s*/, ""
        #/dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        EOF
      end

      it "should set enabled to false" do
        provider.load_current_resource
        expect(provider.current_resource.enabled).to be_falsey
      end
    end
  end

  context "after the mount's state has been discovered" do
    describe "mount_fs" do
      it "should mount the filesystem" do
        expect(provider).to receive(:shell_out!).with("mount -F #{fstype} -o defaults #{device} #{mountpoint}")
        provider.mount_fs()
      end

      it "should mount the filesystem with options if options were passed" do
        options = "logging,noatime,largefiles,nosuid,rw,quota"
        new_resource.options(options.split(/,/))
        expect(provider).to receive(:shell_out!).with("mount -F #{fstype} -o #{options} #{device} #{mountpoint}")
        provider.mount_fs()
      end

      it "should delete the 'noauto' magic option" do
        options = "rw,noauto"
        new_resource.options(%w{rw noauto})
        expect(provider).to receive(:shell_out!).with("mount -F #{fstype} -o rw #{device} #{mountpoint}")
        provider.mount_fs()
      end
    end

    describe "umount_fs" do
      it "should umount the filesystem if it is mounted" do
        expect(provider).to receive(:shell_out!).with("umount #{mountpoint}")
        provider.umount_fs()
      end
    end

    describe "remount_fs without options and do not mount at boot" do
      it "should use mount -o remount" do
        new_resource.options(%w{noauto})
        expect(provider).to receive(:shell_out!).with("mount -o remount #{new_resource.mount_point}")
        provider.remount_fs
      end
    end

    describe "remount_fs with options and do not mount at boot" do
      it "should use mount -o remount,rw" do
        new_resource.options(%w{rw noauto})
        expect(provider).to receive(:shell_out!).with("mount -o remount,rw #{new_resource.mount_point}")
        provider.remount_fs
      end
    end

    describe "remount_fs with options and mount at boot" do
      it "should use mount -o remount,rw" do
        new_resource.options(%w{rw})
        expect(provider).to receive(:shell_out!).with("mount -o remount,rw #{new_resource.mount_point}")
        provider.remount_fs
      end
    end

    describe "remount_fs without options and mount at boot" do
      it "should use mount -o remount" do
        new_resource.options([])
        expect(provider).to receive(:shell_out!).with("mount -o remount #{new_resource.mount_point}")
        provider.remount_fs
      end
    end

    describe "when enabling the fs" do
      context "in the typical case" do
        let(:other_mount) { "/dev/dsk/c0t2d0s0       /dev/rdsk/c0t2d0s0      /            ufs     2       yes     -" }

        let(:this_mount) { "/dev/dsk/c0t2d0s7\t/dev/rdsk/c0t2d0s7\t/mnt/foo\tufs\t2\tyes\tdefaults\n" }

        let(:vfstab_file_contents) { [other_mount].join("\n") }

        before do
          allow(provider).to receive(:etc_tempfile).and_yield(Tempfile.open("vfstab"))
          provider.load_current_resource
          provider.enable_fs
        end

        it "should leave the other mountpoint alone" do
          expect(IO.read(vfstab_file.path)).to match(/^#{Regexp.escape(other_mount)}/)
        end

        it "should enable the mountpoint we care about" do
          expect(IO.read(vfstab_file.path)).to match(/^#{Regexp.escape(this_mount)}/)
        end
      end

      context "when the mount has options=noauto" do
        let(:other_mount) { "/dev/dsk/c0t2d0s0       /dev/rdsk/c0t2d0s0      /            ufs     2       yes     -" }

        let(:this_mount) { "/dev/dsk/c0t2d0s7\t/dev/rdsk/c0t2d0s7\t/mnt/foo\tufs\t2\tno\t-\n" }

        let(:options) { "noauto" }

        let(:vfstab_file_contents) { [other_mount].join("\n") }

        before do
          allow(provider).to receive(:etc_tempfile).and_yield(Tempfile.open("vfstab"))
          provider.load_current_resource
          provider.enable_fs
        end

        it "should leave the other mountpoint alone" do
          expect(IO.read(vfstab_file.path)).to match(/^#{Regexp.escape(other_mount)}/)
        end

        it "should enable the mountpoint we care about" do
          expect(IO.read(vfstab_file.path)).to match(/^#{Regexp.escape(this_mount)}/)
        end
      end

      context "when the new mount has options of noauto and the existing mount has mount at boot yes" do
        let(:existing_mount) { "/dev/dsk/c0t2d0s7\t/dev/rdsk/c0t2d0s7\t/mnt/foo\tufs\t2\tyes\t-" }

        let(:this_mount) { "/dev/dsk/c0t2d0s7\t/dev/rdsk/c0t2d0s7\t/mnt/foo\tufs\t2\tno\t-\n" }

        let(:options) { "noauto" }

        let(:vfstab_file_contents) { [existing_mount].join("\n") }

        before do
          allow(provider).to receive(:etc_tempfile).and_yield(Tempfile.open("vfstab"))
          provider.load_current_resource
          provider.mount_options_unchanged?
          provider.send(:vfstab_entry)
        end

        it "should detect a changed entry" do
          expect(provider.mount_options_unchanged?).to eq(false)
        end

        it "should change mount at boot to no" do
          expect(provider.send(:vfstab_entry)).to match(/^#{Regexp.escape(this_mount)}/)
        end
      end

      context "when the new mount has options of - and the existing mount has mount at boot no" do
        let(:existing_mount) { "/dev/dsk/c0t2d0s7\t/dev/rdsk/c0t2d0s7\t/mnt/foo\tufs\t2\tno\t-" }

        let(:this_mount) { "/dev/dsk/c0t2d0s7\t/dev/rdsk/c0t2d0s7\t/mnt/foo\tufs\t2\tyes\t-\n" }

        let(:options) { "-" }

        let(:vfstab_file_contents) { [existing_mount].join("\n") }

        before do
          allow(provider).to receive(:etc_tempfile).and_yield(Tempfile.open("vfstab"))
          provider.load_current_resource
          provider.mount_options_unchanged?
          provider.send(:vfstab_entry)
        end

        it "should detect a changed entry" do
          expect(provider.mount_options_unchanged?).to eq(false)
        end

        it "should change mount at boot to yes" do
          expect(provider.send(:vfstab_entry)).to match(/^#{Regexp.escape(this_mount)}/)
        end
      end

      context "when the new mount has options of noauto and the existing mount has mount at boot no" do
        let(:existing_mount) { "/dev/dsk/c0t2d0s7\t/dev/rdsk/c0t2d0s7\t/mnt/foo\tufs\t2\tno\t-" }

        let(:this_mount) { "/dev/dsk/c0t2d0s7\t/dev/rdsk/c0t2d0s7\t/mnt/foo\tufs\t2\tno\t-\n" }

        let(:options) { "-,noauto" }

        let(:vfstab_file_contents) { [existing_mount].join("\n") }

        before do
          allow(provider).to receive(:etc_tempfile).and_yield(Tempfile.open("vfstab"))
          provider.load_current_resource
          provider.mount_options_unchanged?
          provider.send(:vfstab_entry)
        end

        it "should detect an unchanged entry" do
          expect(provider.mount_options_unchanged?).to eq(true)
        end

        it "should not change mount at boot" do
          expect(provider.send(:vfstab_entry)).to match(/^#{Regexp.escape(this_mount)}/)
        end
      end

      context "when the new mount has options of - and the existing mount has mount at boot yes" do
        let(:existing_mount) { "/dev/dsk/c0t2d0s7\t/dev/rdsk/c0t2d0s7\t/mnt/foo\tufs\t2\tyes\t-" }

        let(:this_mount) { "/dev/dsk/c0t2d0s7\t/dev/rdsk/c0t2d0s7\t/mnt/foo\tufs\t2\tyes\t-\n" }

        let(:options) { "-" }

        let(:vfstab_file_contents) { [existing_mount].join("\n") }

        before do
          allow(provider).to receive(:etc_tempfile).and_yield(Tempfile.open("vfstab"))
          provider.load_current_resource
          provider.mount_options_unchanged?
          provider.send(:vfstab_entry)
        end

        it "should detect an unchanged entry" do
          expect(provider.mount_options_unchanged?).to eq(true)
        end

        it "should not change mount at boot" do
          expect(provider.send(:vfstab_entry)).to match(/^#{Regexp.escape(this_mount)}/)
        end
      end
    end

    describe "when disabling the fs" do
      context "in the typical case" do
        let(:other_mount) { "/dev/dsk/c0t2d0s0       /dev/rdsk/c0t2d0s0      /            ufs     2       yes     -" }

        let(:this_mount) { "/dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -" }

        let(:vfstab_file_contents) { [other_mount, this_mount].join("\n") }

        before do
          allow(provider).to receive(:etc_tempfile).and_yield(Tempfile.open("vfstab"))
          provider.disable_fs
        end

        it "should leave the other mountpoint alone" do
          expect(IO.read(vfstab_file.path)).to match(/^#{Regexp.escape(other_mount)}/)
        end

        it "should disable the mountpoint we care about" do
          expect(IO.read(vfstab_file.path)).not_to match(/^#{Regexp.escape(this_mount)}/)
        end
      end

      context "when there is a commented out line" do
        let(:other_mount) { "/dev/dsk/c0t2d0s0       /dev/rdsk/c0t2d0s0      /            ufs     2       yes     -" }

        let(:this_mount) { "/dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -" }

        let(:comment) { "#/dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -" }

        let(:vfstab_file_contents) { [other_mount, this_mount, comment].join("\n") }

        before do
          allow(provider).to receive(:etc_tempfile).and_yield(Tempfile.open("vfstab"))
          provider.disable_fs
        end

        it "should leave the other mountpoint alone" do
          expect(IO.read(vfstab_file.path)).to match(/^#{Regexp.escape(other_mount)}/)
        end

        it "should disable the mountpoint we care about" do
          expect(IO.read(vfstab_file.path)).not_to match(/^#{Regexp.escape(this_mount)}/)
        end

        it "should keep the comment" do
          expect(IO.read(vfstab_file.path)).to match(/^#{Regexp.escape(comment)}/)
        end
      end

      context "when there is a duplicated line" do
        let(:other_mount) { "/dev/dsk/c0t2d0s0       /dev/rdsk/c0t2d0s0      /            ufs     2       yes     -" }

        let(:this_mount) { "/dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -" }

        let(:vfstab_file_contents) { [this_mount, other_mount, this_mount].join("\n") }

        before do
          allow(provider).to receive(:etc_tempfile).and_yield(Tempfile.open("vfstab"))
          provider.disable_fs
        end

        it "should leave the other mountpoint alone" do
          expect(IO.read(vfstab_file.path)).to match(/^#{Regexp.escape(other_mount)}/)
        end

        it "should still match the duplicated mountpoint" do
          expect(IO.read(vfstab_file.path)).to match(/^#{Regexp.escape(this_mount)}/)
        end

        it "should have removed the last line" do
          expect(IO.read(vfstab_file.path)).to eql( "#{this_mount}\n#{other_mount}\n" )
        end
      end
    end
  end
end
