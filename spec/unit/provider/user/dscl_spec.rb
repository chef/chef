#
# Author:: Dreamcat4 (<dreamcat4@gmail.com>)
# Copyright:: Copyright (c) 2009 OpsCode, Inc.
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

ShellCmdResult = Struct.new(:stdout, :stderr, :exitstatus)

require 'spec_helper'
require 'ostruct'
require 'mixlib/shellout'

describe Chef::Provider::User::Dscl do
  let(:node) {
    node = Chef::Node.new
    node.stub(:[]).with(:platform_version).and_return(mac_version)
    node.stub(:[]).with(:platform).and_return("mac_os_x")
    node
  }

  let(:events) {
    Chef::EventDispatch::Dispatcher.new
  }

  let(:run_context) {
    Chef::RunContext.new(node, {}, events)
  }

  let(:new_resource) {
    r = Chef::Resource::User.new("toor")
    r.password(password)
    r.salt(salt)
    r.iterations(iterations)
    r
  }

  let(:provider) {
    Chef::Provider::User::Dscl.new(new_resource, run_context)
  }

  let(:mac_version) {
    "10.9.1"
  }

  let(:password) { nil }
  let(:salt) { nil }
  let(:iterations) { nil }

  let(:salted_sha512_password) {
    "0f543f021c63255e64e121a3585601b8ecfedf6d2\
705ddac69e682a33db5dbcdb9b56a2520bc8fff63a\
2ba6b7984c0737ff0b7949455071581f7affcd536d\
402b6cdb097"
  }

  let(:salted_sha512_pbkdf2_password) {
    "c734b6e4787c3727bb35e29fdd92b97c\
1de12df509577a045728255ec7c6c5f5\
c18efa05ed02b682ffa7ebc05119900e\
b1d4880833aa7a190afc13e2bf0936b8\
20123e8c98f0f9bcac2a629d9163caac\
9464a8c234f3919082400b4f939bb77b\
c5adbbac718b7eb99463a7b679571e0f\
1c9fef2ef08d0b9e9c2bcf644eed2ffc"
  }

  let(:salted_sha512_pbkdf2_salt) {
    "2d942d8364a9ccf2b8e5cb7ed1ff58f78\
e29dbfee7f9db58859144d061fd0058"
  }

  let(:salted_sha512_pbkdf2_iterations) {
    25000
  }

  let(:vagrant_sha_512) {
    "6f75d7190441facc34291ebbea1fc756b242d4f\
e9bcff141bccb84f1979e27e539539aa31f9f7dcc92c0cea959\
ea18e18b720e358e7fbe3cfbeaa561456f6ba008937a30"
  }

  let(:vagrant_sha_512_pbkdf2) {
    "12601a90db17cbf\
8ba4808e6382fb0d3b9d8a6c1a190477bf680ab21afb\
6065467136e55cc208a6f74156e3daf20fb13369ef4b\
7bafa047d80359fb46a48a4adccd548ebb33851b093\
47cca84341a7f93a27147343f89fb843fb46c0017d2\
64afa4976baacf941b915bd1ec1ca24c30b3e759e02\
403e02f59fe7ff5938a7636c"
  }

  let(:vagrant_sha_512_pbkdf2_salt) {
    "ee954be472fdc60ddf89484781433993625f006af6ec810c08f49a7e413946a1"
  }

  let(:vagrant_sha_512_pbkdf2_iterations) {
    34482
  }

  describe "when shelling out to dscl" do
    it "should run dscl with the supplied cmd /Path args" do
      shell_return = ShellCmdResult.new('stdout', 'err', 0)
      provider.should_receive(:shell_out).with("dscl . -cmd /Path args").and_return(shell_return)
      provider.run_dscl("cmd /Path args").should == 'stdout'
    end

    it "returns an empty string from delete commands" do
      shell_return = ShellCmdResult.new('out', 'err', 23)
      provider.should_receive(:shell_out).with("dscl . -delete /Path args").and_return(shell_return)
      provider.run_dscl("delete /Path args").should == ""
    end

    it "should raise an exception for any other command" do
      shell_return = ShellCmdResult.new('out', 'err', 23)
      provider.should_receive(:shell_out).with('dscl . -cmd /Path arguments').and_return(shell_return)
      lambda { provider.run_dscl("cmd /Path arguments") }.should raise_error(Chef::Exceptions::DsclCommandFailed)
    end

    it "raises an exception when dscl reports 'no such key'" do
      shell_return = ShellCmdResult.new("No such key: ", 'err', 23)
      provider.should_receive(:shell_out).with('dscl . -cmd /Path args').and_return(shell_return)
      lambda { provider.run_dscl("cmd /Path args") }.should raise_error(Chef::Exceptions::DsclCommandFailed)
    end

    it "raises an exception when dscl reports 'eDSRecordNotFound'" do
      shell_return = ShellCmdResult.new("<dscl_cmd> DS Error: -14136 (eDSRecordNotFound)", 'err', -14136)
      provider.should_receive(:shell_out).with('dscl . -cmd /Path args').and_return(shell_return)
      lambda { provider.run_dscl("cmd /Path args") }.should raise_error(Chef::Exceptions::DsclCommandFailed)
    end
  end

  describe "get_free_uid" do
    before do
      provider.should_receive(:run_dscl).with("list /Users uid").and_return("\nwheel      200\nstaff      201\nbrahms      500\nchopin      501\n")
    end

    describe "when resource is configured as system" do
      before do
        new_resource.system(true)
      end

      it "should return the first unused uid number on or above 500" do
        provider.get_free_uid.should eq(202)
      end
    end

    it "should return the first unused uid number on or above 200" do
      provider.get_free_uid.should eq(502)
    end

    it "should raise an exception when the search limit is exhausted" do
      search_limit = 1
      lambda { provider.get_free_uid(search_limit) }.should raise_error(RuntimeError)
    end
  end

  describe "uid_used?" do
    it "should return false if not given any valid uid number" do
      provider.uid_used?(nil).should be_false
    end

    describe "when called with a user id" do
      before do
        provider.should_receive(:run_dscl).with("list /Users uid").and_return("\naj      500\n")
      end

      it "should return true for a used uid number" do
        provider.uid_used?(500).should be_true
      end

      it "should return false for an unused uid number" do
        provider.uid_used?(501).should be_false
      end
    end
  end

  describe "when determining the uid to set" do
    it "raises RequestedUIDUnavailable if the requested uid is already in use" do
      provider.stub(:uid_used?).and_return(true)
      provider.should_receive(:get_free_uid).and_return(501)
      lambda { provider.dscl_set_uid }.should raise_error(Chef::Exceptions::RequestedUIDUnavailable)
    end

    it "finds a valid, unused uid when none is specified" do
      provider.should_receive(:run_dscl).with("list /Users uid").and_return('')
      provider.should_receive(:run_dscl).with("create /Users/toor UniqueID 501")
      provider.should_receive(:get_free_uid).and_return(501)
      provider.dscl_set_uid
      new_resource.uid.should eq(501)
    end

    it "sets the uid specified in the resource" do
      new_resource.uid(1000)
      provider.should_receive(:run_dscl).with("create /Users/toor UniqueID 1000").and_return(true)
      provider.should_receive(:run_dscl).with("list /Users uid").and_return('')
      provider.dscl_set_uid
    end
  end

  describe "when modifying the home directory" do
    let(:current_resource) {
      new_resource.dup
    }

    before do
      new_resource.supports({ :manage_home => true })
      new_resource.home('/Users/toor')

      provider.current_resource = current_resource
    end

    it "deletes the home directory when resource#home is nil" do
      new_resource.instance_variable_set(:@home, nil)
      provider.should_receive(:run_dscl).with("delete /Users/toor NFSHomeDirectory").and_return(true)
      provider.dscl_set_home
    end


    it "raises InvalidHomeDirectory when the resource's home directory doesn't look right" do
      new_resource.home('epic-fail')
      lambda { provider.dscl_set_home }.should raise_error(Chef::Exceptions::InvalidHomeDirectory)
    end

    it "moves the users home to the new location if it exists and the target location is different" do
      new_resource.supports(:manage_home => true)

      current_home = CHEF_SPEC_DATA + '/old_home_dir'
      current_home_files = [current_home + '/my-dot-emacs', current_home + '/my-dot-vim']
      current_resource.home(current_home)
      new_resource.gid(23)
      ::File.stub(:exists?).with('/old/home/toor').and_return(true)
      ::File.stub(:exists?).with('/Users/toor').and_return(true)

      FileUtils.should_receive(:mkdir_p).with('/Users/toor').and_return(true)
      FileUtils.should_receive(:rmdir).with(current_home)
      ::Dir.should_receive(:glob).with("#{CHEF_SPEC_DATA}/old_home_dir/*",::File::FNM_DOTMATCH).and_return(current_home_files)
      FileUtils.should_receive(:mv).with(current_home_files, "/Users/toor", :force => true)
      FileUtils.should_receive(:chown_R).with('toor','23','/Users/toor')

      provider.should_receive(:run_dscl).with("create /Users/toor NFSHomeDirectory '/Users/toor'")
      provider.dscl_set_home
    end

    it "should raise an exception when the systems user template dir (skel) cannot be found" do
      ::File.stub(:exists?).and_return(false,false,false)
      lambda { provider.dscl_set_home }.should raise_error(Chef::Exceptions::User)
    end

    it "should run ditto to copy any missing files from skel to the new home dir" do
      ::File.should_receive(:exists?).with("/System/Library/User\ Template/English.lproj").and_return(true)
      FileUtils.should_receive(:chown_R).with('toor', '', '/Users/toor')
      provider.should_receive(:shell_out!).with("ditto '/System/Library/User Template/English.lproj' '/Users/toor'")
      provider.ditto_home
    end

    it "creates the user's NFSHomeDirectory and home directory" do
      provider.should_receive(:run_dscl).with("create /Users/toor NFSHomeDirectory '/Users/toor'").and_return(true)
      provider.should_receive(:ditto_home)
      provider.dscl_set_home
    end
  end

  describe "resource_requirements" do
    let(:dscl_exists) { true }
    let(:plutil_exists) { true }

    before do
      ::File.stub(:exists?).with("/usr/bin/dscl").and_return(dscl_exists)
      ::File.stub(:exists?).with("/usr/bin/plutil").and_return(plutil_exists)
    end

    def run_requirements
      provider.define_resource_requirements
      provider.action = :create
      provider.process_resource_requirements
    end

    describe "when dscl doesn't exist" do
      let(:dscl_exists) { false }

      it "should raise an error" do
        lambda { run_requirements }.should raise_error
      end
    end

    describe "when plutil doesn't exist" do
      let(:plutil_exists) { false }

      it "should raise an error" do
        lambda { run_requirements }.should raise_error
      end
    end

    describe "when on Mac 10.6" do
      let(:mac_version) {
        "10.6.5"
      }

      it "should raise an error" do
        lambda { run_requirements }.should raise_error
      end
    end

    describe "when on Mac 10.7" do
      let(:mac_version) {
        "10.7.5"
      }

      describe "when password is SALTED-SHA512" do
        let(:password) { salted_sha512_password }

        it "should not raise an error" do
          lambda { run_requirements }.should_not raise_error
        end
      end

      describe "when password is SALTED-SHA512-PBKDF2" do
        let(:password) { salted_sha512_pbkdf2_password }

        it "should raise an error" do
          lambda { run_requirements }.should raise_error
        end
      end
    end

    [ "10.9", "10.10"].each do |version|
      describe "when on Mac #{version}" do
        let(:mac_version) {
          "#{version}.2"
        }

        describe "when password is SALTED-SHA512" do
          let(:password) { salted_sha512_password }

          it "should raise an error" do
            lambda { run_requirements }.should raise_error
          end
        end

        describe "when password is SALTED-SHA512-PBKDF2" do
          let(:password) { salted_sha512_pbkdf2_password }

          describe "when salt and iteration is not set" do
            it "should raise an error" do
              lambda { run_requirements }.should raise_error
            end
          end

          describe "when salt and iteration is set" do
            let(:salt) { salted_sha512_pbkdf2_salt }
            let(:iterations) { salted_sha512_pbkdf2_iterations }

            it "should not raise an error" do
              lambda { run_requirements }.should_not raise_error
            end
          end
        end
      end
    end
  end

  describe "load_current_resource" do
    # set this to any of the user plist files under spec/data
    let(:user_plist_file) { nil }

    before do
      provider.should_receive(:shell_out).with("plutil -convert xml1 -o - /var/db/dslocal/nodes/Default/users/toor.plist") do
        if user_plist_file.nil?
          ShellCmdResult.new('Can not find the file', 'Sorry!!', 1)
        else
          ShellCmdResult.new(File.read(File.join(CHEF_SPEC_DATA, "mac_users/#{user_plist_file}.plist.xml")), "", 0)
        end
      end

      if !user_plist_file.nil?
        provider.should_receive(:convert_binary_plist_to_xml).and_return(File.read(File.join(CHEF_SPEC_DATA, "mac_users/#{user_plist_file}.shadow.xml")))
      end
    end

    describe "when user is not there" do
      it "shouldn't raise an error" do
        lambda { provider.load_current_resource }.should_not raise_error
      end

      it "should set @user_exists" do
        provider.load_current_resource
        provider.instance_variable_get(:@user_exists).should be_false
      end

      it "should set username" do
        provider.load_current_resource
        provider.current_resource.username.should eq("toor")
      end
    end

    describe "when user is there" do
      let(:password) { "something" } # Load password during load_current_resource

      describe "on 10.7" do
        let(:mac_version) {
          "10.7.5"
        }

        let(:user_plist_file) { "10.7" }

        it "collects the user data correctly" do
          provider.load_current_resource
          provider.current_resource.comment.should eq("vagrant")
          provider.current_resource.uid.should eq("11112222-3333-4444-AAAA-BBBBCCCCDDDD")
          provider.current_resource.gid.should eq("80")
          provider.current_resource.home.should eq("/Users/vagrant")
          provider.current_resource.shell.should eq("/bin/bash")
          provider.current_resource.password.should eq(vagrant_sha_512)
        end

        describe "when a plain password is set that is same" do
          let(:password) { "vagrant" }

          it "diverged_password? should report false" do
            provider.load_current_resource
            provider.diverged_password?.should be_false
          end
        end

        describe "when a plain password is set that is different" do
          let(:password) { "not_vagrant" }

          it "diverged_password? should report true" do
            provider.load_current_resource
            provider.diverged_password?.should be_true
          end
        end

        describe "when iterations change" do
          let(:password) { vagrant_sha_512 }
          let(:iterations) { 12345 }

          it "diverged_password? should report false" do
            provider.load_current_resource
            provider.diverged_password?.should be_false
          end
        end

        describe "when shadow hash changes" do
          let(:password) { salted_sha512_password }

          it "diverged_password? should report true" do
            provider.load_current_resource
            provider.diverged_password?.should be_true
          end
        end

        describe "when salt change" do
          let(:password) { vagrant_sha_512 }
          let(:salt) { "SOMETHINGRANDOM" }

          it "diverged_password? should report false" do
            provider.load_current_resource
            provider.diverged_password?.should be_false
          end
        end
      end

      describe "on 10.8" do
        let(:mac_version) {
          "10.8.3"
        }

        let(:user_plist_file) { "10.8" }

        it "collects the user data correctly" do
          provider.load_current_resource
          provider.current_resource.comment.should eq("vagrant")
          provider.current_resource.uid.should eq("11112222-3333-4444-AAAA-BBBBCCCCDDDD")
          provider.current_resource.gid.should eq("80")
          provider.current_resource.home.should eq("/Users/vagrant")
          provider.current_resource.shell.should eq("/bin/bash")
          provider.current_resource.password.should eq("ea4c2d265d801ba0ec0dfccd\
253dfc1de91cbe0806b4acc1ed7fe22aebcf6beb5344d0f442e590\
ffa04d679075da3afb119e41b72b5eaf08ee4aa54693722646d5\
19ee04843deb8a3e977428d33f625e83887913e5c13b70035961\
5e00ad7bc3e7a0c98afc3e19d1360272454f8d33a9214d2fbe8b\
e68d1f9821b26689312366")
          provider.current_resource.salt.should eq("f994ef2f73b7c5594ebd1553300976b20733ce0e24d659783d87f3d81cbbb6a9")
          provider.current_resource.iterations.should eq(39840)
        end
      end

      describe "on 10.7 upgraded to 10.8" do
        # In this scenario user password is still in 10.7 format
        let(:mac_version) {
          "10.8.3"
        }

        let(:user_plist_file) { "10.7-8" }

        it "collects the user data correctly" do
          provider.load_current_resource
          provider.current_resource.comment.should eq("vagrant")
          provider.current_resource.uid.should eq("11112222-3333-4444-AAAA-BBBBCCCCDDDD")
          provider.current_resource.gid.should eq("80")
          provider.current_resource.home.should eq("/Users/vagrant")
          provider.current_resource.shell.should eq("/bin/bash")
          provider.current_resource.password.should eq("6f75d7190441facc34291ebbea1fc756b242d4f\
e9bcff141bccb84f1979e27e539539aa31f9f7dcc92c0cea959\
ea18e18b720e358e7fbe3cfbeaa561456f6ba008937a30")
        end

        describe "when a plain text password is set" do
          it "reports password needs to be updated" do
            provider.load_current_resource
            provider.diverged_password?.should be_true
          end
        end

        describe "when a salted-sha512-pbkdf2 shadow is set" do
          let(:password) { salted_sha512_pbkdf2_password }
          let(:salt) { salted_sha512_pbkdf2_salt }
          let(:iterations) { salted_sha512_pbkdf2_iterations }

          it "reports password needs to be updated" do
            provider.load_current_resource
            provider.diverged_password?.should be_true
          end
        end
      end

      describe "on 10.9" do
        let(:mac_version) {
          "10.9.1"
        }

        let(:user_plist_file) { "10.9" }

        it "collects the user data correctly" do
          provider.load_current_resource
          provider.current_resource.comment.should eq("vagrant")
          provider.current_resource.uid.should eq("11112222-3333-4444-AAAA-BBBBCCCCDDDD")
          provider.current_resource.gid.should eq("80")
          provider.current_resource.home.should eq("/Users/vagrant")
          provider.current_resource.shell.should eq("/bin/bash")
          provider.current_resource.password.should eq(vagrant_sha_512_pbkdf2)
          provider.current_resource.salt.should eq(vagrant_sha_512_pbkdf2_salt)
          provider.current_resource.iterations.should eq(vagrant_sha_512_pbkdf2_iterations)
        end

        describe "when a plain password is set that is same" do
          let(:password) { "vagrant" }

          it "diverged_password? should report false" do
            provider.load_current_resource
            provider.diverged_password?.should be_false
          end
        end

        describe "when a plain password is set that is different" do
          let(:password) { "not_vagrant" }

          it "diverged_password? should report true" do
            provider.load_current_resource
            provider.diverged_password?.should be_true
          end
        end

        describe "when iterations change" do
          let(:password) { vagrant_sha_512_pbkdf2 }
          let(:salt) { vagrant_sha_512_pbkdf2_salt }
          let(:iterations) { 12345 }

          it "diverged_password? should report true" do
            provider.load_current_resource
            provider.diverged_password?.should be_true
          end
        end

        describe "when shadow hash changes" do
          let(:password) { salted_sha512_pbkdf2_password }
          let(:salt) { vagrant_sha_512_pbkdf2_salt }
          let(:iterations) { vagrant_sha_512_pbkdf2_iterations }

          it "diverged_password? should report true" do
            provider.load_current_resource
            provider.diverged_password?.should be_true
          end
        end

        describe "when salt change" do
          let(:password) { vagrant_sha_512_pbkdf2 }
          let(:salt) { salted_sha512_pbkdf2_salt }
          let(:iterations) { vagrant_sha_512_pbkdf2_iterations }

          it "diverged_password? should report true" do
            provider.load_current_resource
            provider.diverged_password?.should be_true
          end
        end
      end
    end
  end

  describe "salted_sha512_pbkdf2?" do
    it "should return true when the string is a salted_sha512_pbkdf2 hash" do
      provider.salted_sha512_pbkdf2?(salted_sha512_pbkdf2_password).should be_true
    end

    it "should return false otherwise" do
      provider.salted_sha512_pbkdf2?(salted_sha512_password).should be_false
      provider.salted_sha512_pbkdf2?("any other string").should be_false
    end
  end

  describe "salted_sha512?" do
    it "should return true when the string is a salted_sha512_pbkdf2 hash" do
      provider.salted_sha512_pbkdf2?(salted_sha512_pbkdf2_password).should be_true
    end

    it "should return false otherwise" do
      provider.salted_sha512?(salted_sha512_pbkdf2_password).should be_false
      provider.salted_sha512?("any other string").should be_false
    end
  end

  describe "prepare_password_shadow_info" do
    describe "when on Mac 10.7" do
      let(:mac_version) {
        "10.7.1"
      }

      describe "when the password is plain text" do
        let(:password) { "vagrant" }

        it "password_shadow_info should have salted-sha-512 format" do
          shadow_info = provider.prepare_password_shadow_info
          shadow_info.should have_key("SALTED-SHA512")
          info = shadow_info["SALTED-SHA512"].string.unpack('H*').first
          provider.salted_sha512?(info).should be_true
        end
      end

      describe "when the password is salted-sha-512" do
        let(:password) { vagrant_sha_512 }

        it "password_shadow_info should have salted-sha-512 format" do
          shadow_info = provider.prepare_password_shadow_info
          shadow_info.should have_key("SALTED-SHA512")
          info = shadow_info["SALTED-SHA512"].string.unpack('H*').first
          provider.salted_sha512?(info).should be_true
          info.should eq(vagrant_sha_512)
        end
      end
    end

    ["10.8", "10.9", "10.10"].each do |version|
      describe "when on Mac #{version}" do
        let(:mac_version) {
          "#{version}.1"
        }

        describe "when the password is plain text" do
          let(:password) { "vagrant" }

          it "password_shadow_info should have salted-sha-512 format" do
            shadow_info = provider.prepare_password_shadow_info
            shadow_info.should have_key("SALTED-SHA512-PBKDF2")
            shadow_info["SALTED-SHA512-PBKDF2"].should have_key("entropy")
            shadow_info["SALTED-SHA512-PBKDF2"].should have_key("salt")
            shadow_info["SALTED-SHA512-PBKDF2"].should have_key("iterations")
            info = shadow_info["SALTED-SHA512-PBKDF2"]["entropy"].string.unpack('H*').first
            provider.salted_sha512_pbkdf2?(info).should be_true
          end
        end

        describe "when the password is salted-sha-512" do
          let(:password) { vagrant_sha_512_pbkdf2 }
          let(:iterations) { vagrant_sha_512_pbkdf2_iterations }
          let(:salt) { vagrant_sha_512_pbkdf2_salt }

          it "password_shadow_info should have salted-sha-512 format" do
            shadow_info = provider.prepare_password_shadow_info
            shadow_info.should have_key("SALTED-SHA512-PBKDF2")
            shadow_info["SALTED-SHA512-PBKDF2"].should have_key("entropy")
            shadow_info["SALTED-SHA512-PBKDF2"].should have_key("salt")
            shadow_info["SALTED-SHA512-PBKDF2"].should have_key("iterations")
            info = shadow_info["SALTED-SHA512-PBKDF2"]["entropy"].string.unpack('H*').first
            provider.salted_sha512_pbkdf2?(info).should be_true
            info.should eq(vagrant_sha_512_pbkdf2)
          end
        end
      end
    end
  end

  describe "set_password" do
    before do
      new_resource.password("something")
    end

    it "should sleep and flush the dscl cache before saving the password" do
      provider.should_receive(:prepare_password_shadow_info).and_return({ })
      mock_shellout = double("Mock::Shellout")
      mock_shellout.stub(:run_command)
      Mixlib::ShellOut.should_receive(:new).and_return(mock_shellout)
      provider.should_receive(:read_user_info)
      provider.should_receive(:dscl_set)
      provider.should_receive(:sleep).with(3)
      provider.should_receive(:shell_out).with("dscacheutil '-flushcache'")
      provider.should_receive(:save_user_info)
      provider.set_password
    end
  end

  describe "when the user does not yet exist and chef is creating it" do
    context "with a numeric gid" do
      before do
        new_resource.comment "#mockssuck"
        new_resource.gid 1001
      end

      it "creates the user, comment field, sets uid, gid, configures the home directory, sets the shell, and sets the password" do
        provider.should_receive :dscl_create_user
        provider.should_receive :dscl_create_comment
        provider.should_receive :dscl_set_uid
        provider.should_receive :dscl_set_gid
        provider.should_receive :dscl_set_home
        provider.should_receive :dscl_set_shell
        provider.should_receive :set_password
        provider.create_user
      end

      it "creates the user and sets the comment field" do
        provider.should_receive(:run_dscl).with("create /Users/toor").and_return(true)
        provider.dscl_create_user
      end

      it "sets the comment field" do
        provider.should_receive(:run_dscl).with("create /Users/toor RealName '#mockssuck'").and_return(true)
        provider.dscl_create_comment
      end

      it "should run run_dscl with create /Users/user PrimaryGroupID to set the users primary group" do
        provider.should_receive(:run_dscl).with("create /Users/toor PrimaryGroupID '1001'").and_return(true)
        provider.dscl_set_gid
      end

      it "should run run_dscl with create /Users/user UserShell to set the users login shell" do
        provider.should_receive(:run_dscl).with("create /Users/toor UserShell '/usr/bin/false'").and_return(true)
        provider.dscl_set_shell
      end
    end

    context "with a non-numeric gid" do
      before do
        new_resource.comment "#mockssuck"
        new_resource.gid "newgroup"
      end

      it "should map the group name to a numeric ID when the group exists" do
        provider.should_receive(:run_dscl).with("read /Groups/newgroup PrimaryGroupID").ordered.and_return("PrimaryGroupID: 1001\n")
        provider.should_receive(:run_dscl).with("create /Users/toor PrimaryGroupID '1001'").ordered.and_return(true)
        provider.dscl_set_gid
      end

      it "should raise an exception when the group does not exist" do
        shell_return = ShellCmdResult.new("<dscl_cmd> DS Error: -14136 (eDSRecordNotFound)", 'err', -14136)
        provider.should_receive(:shell_out).with('dscl . -read /Groups/newgroup PrimaryGroupID').and_return(shell_return)
        lambda { provider.dscl_set_gid }.should raise_error(Chef::Exceptions::GroupIDNotFound)
      end
    end
  end

  describe "when the user exists and chef is managing it" do
    before do
      current_resource = new_resource.dup
      provider.current_resource = current_resource

      # These are all different from current_resource
      new_resource.username "mud"
      new_resource.uid 2342
      new_resource.gid 2342
      new_resource.home '/Users/death'
      new_resource.password 'goaway'
    end

    it "sets the user, comment field, uid, gid, moves the home directory, sets the shell, and sets the password" do
      provider.should_receive :dscl_create_user
      provider.should_receive :dscl_create_comment
      provider.should_receive :dscl_set_uid
      provider.should_receive :dscl_set_gid
      provider.should_receive :dscl_set_home
      provider.should_receive :dscl_set_shell
      provider.should_receive :set_password
      provider.create_user
    end
  end

  describe "when changing the gid" do
    before do
      current_resource = new_resource.dup
      provider.current_resource = current_resource

      # This is different from current_resource
      new_resource.gid 2342
    end

    it "sets the gid" do
      provider.should_receive :dscl_set_gid
      provider.manage_user
    end
  end

  describe "when the user exists" do
    before do
      provider.should_receive(:shell_out).with("plutil -convert xml1 -o - /var/db/dslocal/nodes/Default/users/toor.plist") do
        ShellCmdResult.new(File.read(File.join(CHEF_SPEC_DATA, "mac_users/10.9.plist.xml")), "", 0)
      end
      provider.load_current_resource
    end

    describe "when Chef is removing the user" do
      it "removes the user from the groups and deletes home directory when the resource is configured to manage home" do
        new_resource.supports({ :manage_home => true })
        provider.should_receive(:run_dscl).with("list /Groups").and_return("my_group\nyour_group\nreal_group\n")
        provider.should_receive(:run_dscl).with("read /Groups/my_group").and_raise(Chef::Exceptions::DsclCommandFailed) # Empty group
        provider.should_receive(:run_dscl).with("read /Groups/your_group").and_return("GroupMembership: not_you")
        provider.should_receive(:run_dscl).with("read /Groups/real_group").and_return("GroupMembership: toor")
        provider.should_receive(:run_dscl).with("delete /Groups/real_group GroupMembership 'toor'")
        provider.should_receive(:run_dscl).with("delete /Users/toor")
        FileUtils.should_receive(:rm_rf).with("/Users/vagrant")
        provider.remove_user
      end
    end

    describe "when user is not locked" do
      it "determines the user as not locked" do
        provider.should_not be_locked
      end
    end

    describe "when user is locked" do
      before do
        auth_authority = provider.instance_variable_get(:@authentication_authority)
        provider.instance_variable_set(:@authentication_authority, auth_authority + ";DisabledUser;")
      end

      it "determines the user as not locked" do
        provider.should be_locked
      end

      it "can unlock the user" do
        provider.should_receive(:run_dscl).with("create /Users/toor AuthenticationAuthority ';ShadowHash;HASHLIST:<SALTED-SHA512-PBKDF2>'")
        provider.unlock_user
      end
    end
  end

  describe "when locking the user" do
    it "should run run_dscl with append /Users/user AuthenticationAuthority ;DisabledUser; to lock the user account" do
      provider.should_receive(:run_dscl).with("append /Users/toor AuthenticationAuthority ';DisabledUser;'")
      provider.lock_user
    end
  end

end
