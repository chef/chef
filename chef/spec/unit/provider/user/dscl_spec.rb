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

describe Chef::Provider::User::Dscl do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::User.new("toor")
    @provider = Chef::Provider::User::Dscl.new(@new_resource, @run_context)
  end
  
  describe "when shelling out to dscl" do
    it "should run dscl with the supplied cmd /Path args" do
      shell_return = ShellCmdResult.new('stdout', 'err', 0)
      @provider.should_receive(:shell_out).with("dscl . -cmd /Path args").and_return(shell_return)
      @provider.safe_dscl("cmd /Path args").should == 'stdout'
    end

    it "returns an empty string from delete commands" do
      shell_return = ShellCmdResult.new('out', 'err', 23)
      @provider.should_receive(:shell_out).with("dscl . -delete /Path args").and_return(shell_return)
      @provider.safe_dscl("delete /Path args").should == ""
    end

    it "should raise an exception for any other command" do
      shell_return = ShellCmdResult.new('out', 'err', 23)
      @provider.should_receive(:shell_out).with('dscl . -cmd /Path arguments').and_return(shell_return)
      lambda { @provider.safe_dscl("cmd /Path arguments") }.should raise_error(Chef::Exceptions::DsclCommandFailed)
    end

    it "raises an exception when dscl reports 'no such key'" do
      shell_return = ShellCmdResult.new("No such key: ", 'err', 23)
      @provider.should_receive(:shell_out).with('dscl . -cmd /Path args').and_return(shell_return)
      lambda { @provider.safe_dscl("cmd /Path args") }.should raise_error(Chef::Exceptions::DsclCommandFailed)
    end

    it "raises an exception when dscl reports 'eDSRecordNotFound'" do
      shell_return = ShellCmdResult.new("<dscl_cmd> DS Error: -14136 (eDSRecordNotFound)", 'err', -14136)
      @provider.should_receive(:shell_out).with('dscl . -cmd /Path args').and_return(shell_return)
      lambda { @provider.safe_dscl("cmd /Path args") }.should raise_error(Chef::Exceptions::DsclCommandFailed)
    end
  end

  describe "get_free_uid" do
    before do
      @provider.stub!(:safe_dscl).and_return("\nwheel      200\nstaff      201\n")
    end
  
    it "should run safe_dscl with list /Users uid" do
      @provider.should_receive(:safe_dscl).with("list /Users uid")
      @provider.get_free_uid
    end

    it "should return the first unused uid number on or above 200" do
      @provider.get_free_uid.should == 202
    end
  
    it "should raise an exception when the search limit is exhausted" do
      search_limit = 1
      lambda { @provider.get_free_uid(search_limit) }.should raise_error(RuntimeError)
    end
  end

  describe "uid_used?" do
    before do
      @provider.stub!(:safe_dscl).and_return("\naj      500\n")
    end

    it "should run safe_dscl with list /Users uid" do
      @provider.should_receive(:safe_dscl).with("list /Users uid")
      @provider.uid_used?(500)
    end
  
    it "should return true for a used uid number" do
      @provider.uid_used?(500).should be_true
    end

    it "should return false for an unused uid number" do
      @provider.uid_used?(501).should be_false
    end

    it "should return false if not given any valid uid number" do
      @provider.uid_used?(nil).should be_false
    end
  end

  describe "when determining the uid to set" do
    it "raises RequestedUIDUnavailable if the requested uid is already in use" do
      @provider.stub!(:uid_used?).and_return(true)
      @provider.should_receive(:get_free_uid).and_return(501)
      lambda { @provider.set_uid }.should raise_error(Chef::Exceptions::RequestedUIDUnavailable)
    end
  
    it "finds a valid, unused uid when none is specified" do
      @provider.should_receive(:safe_dscl).with("list /Users uid").and_return('')
      @provider.should_receive(:safe_dscl).with("create /Users/toor UniqueID 501")
      @provider.should_receive(:get_free_uid).and_return(501)
      @provider.set_uid
      @new_resource.uid.should == 501
    end
  
    it "sets the uid specified in the resource" do
      @new_resource.uid(1000)
      @provider.should_receive(:safe_dscl).with("create /Users/toor UniqueID 1000").and_return(true)
      @provider.should_receive(:safe_dscl).with("list /Users uid").and_return('')
      @provider.set_uid
    end
  end

  describe "when modifying the home directory" do
    before do
      @new_resource.supports({ :manage_home => true })
      @new_resource.home('/Users/toor')
      
      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
    end

    it "deletes the home directory when resource#home is nil" do
      @new_resource.instance_variable_set(:@home, nil)
      @provider.should_receive(:safe_dscl).with("delete /Users/toor NFSHomeDirectory").and_return(true)
      @provider.modify_home
    end
  

    it "raises InvalidHomeDirectory when the resource's home directory doesn't look right" do
      @new_resource.home('epic-fail')
      lambda { @provider.modify_home }.should raise_error(Chef::Exceptions::InvalidHomeDirectory)
    end

    it "moves the users home to the new location if it exists and the target location is different" do
      @new_resource.supports(:manage_home => true)
      
      current_home = CHEF_SPEC_DATA + '/old_home_dir'
      current_home_files = [current_home + '/my-dot-emacs', current_home + '/my-dot-vim']
      @current_resource.home(current_home)
      @new_resource.gid(23)
      ::File.stub!(:exists?).with('/old/home/toor').and_return(true)
      ::File.stub!(:exists?).with('/Users/toor').and_return(true)
    
      FileUtils.should_receive(:mkdir_p).with('/Users/toor').and_return(true)
      FileUtils.should_receive(:rmdir).with(current_home)
      ::Dir.should_receive(:glob).with("#{CHEF_SPEC_DATA}/old_home_dir/*",::File::FNM_DOTMATCH).and_return(current_home_files)
      FileUtils.should_receive(:mv).with(current_home_files, "/Users/toor", :force => true)
      FileUtils.should_receive(:chown_R).with('toor','23','/Users/toor')
      
      @provider.should_receive(:safe_dscl).with("create /Users/toor NFSHomeDirectory '/Users/toor'")
      @provider.modify_home
    end

    it "should raise an exception when the systems user template dir (skel) cannot be found" do
      ::File.stub!(:exists?).and_return(false,false,false)
      lambda { @provider.modify_home }.should raise_error(Chef::Exceptions::User)
    end

    it "should run ditto to copy any missing files from skel to the new home dir" do
      ::File.should_receive(:exists?).with("/System/Library/User\ Template/English.lproj").and_return(true)
      FileUtils.should_receive(:chown_R).with('toor', '', '/Users/toor')
      @provider.should_receive(:shell_out!).with("ditto '/System/Library/User Template/English.lproj' '/Users/toor'")
      @provider.ditto_home
    end

    it "creates the user's NFSHomeDirectory and home directory" do
      @provider.should_receive(:safe_dscl).with("create /Users/toor NFSHomeDirectory '/Users/toor'").and_return(true)
      @provider.should_receive(:ditto_home)
      @provider.modify_home
    end
  end

  describe "osx_shadow_hash?" do
    it "should return true when the string is a shadow hash" do
      @provider.osx_shadow_hash?("0"*8*155).should eql(true)
    end

    it "should return false otherwise" do
      @provider.osx_shadow_hash?("any other string").should eql(false)
    end
  end

  describe "when detecting the format of a password" do
    it "detects a OS X salted sha1" do
      @provider.osx_salted_sha1?("0"*48).should eql(true)
      @provider.osx_salted_sha1?("any other string").should eql(false)
    end
  end

  describe "guid" do
    it "should run safe_dscl with read /Users/user GeneratedUID to get the users GUID" do
      expected_uuid = "b398449e-cee0-45e0-80f8-b0b5b1bfdeaa"
      @provider.should_receive(:safe_dscl).with("read /Users/toor GeneratedUID").and_return(expected_uuid + "\n")
      @provider.guid.should == expected_uuid
    end
  end

  describe "shadow_hash_set?" do

    it "should run safe_dscl with read /Users/user to see if the AuthenticationAuthority key exists" do
      @provider.should_receive(:safe_dscl).with("read /Users/toor")
      @provider.shadow_hash_set?
    end

    describe "when the user account has an AuthenticationAuthority key" do
      it "uses the shadow hash when there is a ShadowHash field in the AuthenticationAuthority key" do
        @provider.should_receive(:safe_dscl).with("read /Users/toor").and_return("\nAuthenticationAuthority: ;ShadowHash;\n")
        @provider.shadow_hash_set?.should be_true
      end

      it "does not use the shadow hash when there is no ShadowHash field in the AuthenticationAuthority key" do
        @provider.should_receive(:safe_dscl).with("read /Users/toor").and_return("\nAuthenticationAuthority: \n")
        @provider.shadow_hash_set?.should be_false
      end

    end

    describe "with no AuthenticationAuthority key in the user account" do
      it "does not use the shadow hash" do
        @provider.should_receive(:safe_dscl).with("read /Users/toor").and_return("")
        @provider.shadow_hash_set?.should eql(false)
      end
    end
  end

  describe "when setting or modifying the user password" do
    before do
      @new_resource.password("password")
      @output = StringIO.new
    end

    describe "when using a salted sha1 for the password" do
      before do
        @new_resource.password("F"*48)
      end
    
      it "should write a shadow hash file with the expected salted sha1" do
        uuid = "B398449E-CEE0-45E0-80F8-B0B5B1BFDEAA"
        File.should_receive(:open).with('/var/db/shadow/hash/B398449E-CEE0-45E0-80F8-B0B5B1BFDEAA', "w", 384).and_yield(@output)
        @provider.should_receive(:safe_dscl).with("read /Users/toor GeneratedUID").and_return(uuid)
        @provider.should_receive(:safe_dscl).with("read /Users/toor").and_return("\nAuthenticationAuthority: ;ShadowHash;\n")
        expected_salted_sha1 = @new_resource.password
        expected_shadow_hash = "00000000"*155
        expected_shadow_hash[168] = expected_salted_sha1
        @provider.modify_password
        @output.string.strip.should == expected_shadow_hash
      end    
    end

    describe "when given a shadow hash file for the password" do
      it "should write the shadow hash file directly to /var/db/shadow/hash/GUID" do
        shadow_hash = '0123456789ABCDE0123456789ABCDEF' * 40
        raise 'oops' unless shadow_hash.size == 1240
        @new_resource.password shadow_hash
        uuid = "B398449E-CEE0-45E0-80F8-B0B5B1BFDEAA"
        File.should_receive(:open).with('/var/db/shadow/hash/B398449E-CEE0-45E0-80F8-B0B5B1BFDEAA', "w", 384).and_yield(@output)
        @provider.should_receive(:safe_dscl).with("read /Users/toor GeneratedUID").and_return(uuid)
        @provider.should_receive(:safe_dscl).with("read /Users/toor").and_return("\nAuthenticationAuthority: ;ShadowHash;\n")
        @provider.modify_password
        @output.string.strip.should == shadow_hash
      end
    end

    describe "when given a string for the password" do
      it "should output a salted sha1 and shadow hash file from the specified password" do
        uuid = "B398449E-CEE0-45E0-80F8-B0B5B1BFDEAA"
        File.should_receive(:open).with('/var/db/shadow/hash/B398449E-CEE0-45E0-80F8-B0B5B1BFDEAA', "w", 384).and_yield(@output)
        @new_resource.password("password")
        OpenSSL::Random.stub!(:random_bytes).and_return("\377\377\377\377\377\377\377\377")
        expected_salted_sha1 = "F"*8+"SHA1-"*8
        expected_shadow_hash = "00000000"*155
        expected_shadow_hash[168] = expected_salted_sha1
        @provider.should_receive(:safe_dscl).with("read /Users/toor GeneratedUID").and_return(uuid)
        @provider.should_receive(:safe_dscl).with("read /Users/toor").and_return("\nAuthenticationAuthority: ;ShadowHash;\n")
        @provider.modify_password
        @output.string.strip.should match(/^0{168}(FFFFFFFF1C1AA7935D4E1190AFEC92343F31F7671FBF126D)0{1071}$/)
      end    
    end

    it "should write the output directly to the shadow hash file at /var/db/shadow/hash/GUID" do
      shadow_file = StringIO.new
      uuid = "B398449E-CEE0-45E0-80F8-B0B5B1BFDEAA"
      File.should_receive(:open).with("/var/db/shadow/hash/B398449E-CEE0-45E0-80F8-B0B5B1BFDEAA",'w',0600).and_yield(shadow_file)
      @provider.should_receive(:safe_dscl).with("read /Users/toor GeneratedUID").and_return(uuid)
      @provider.should_receive(:safe_dscl).with("read /Users/toor").and_return("\nAuthenticationAuthority: ;ShadowHash;\n")
      @provider.modify_password
      shadow_file.string.should match(/^0{168}[0-9A-F]{48}0{1071}$/)
    end

    it "should run safe_dscl append /Users/user AuthenticationAuthority ;ShadowHash; when no shadow hash set" do
      shadow_file = StringIO.new
      uuid = "B398449E-CEE0-45E0-80F8-B0B5B1BFDEAA"
      File.should_receive(:open).with("/var/db/shadow/hash/B398449E-CEE0-45E0-80F8-B0B5B1BFDEAA",'w',0600).and_yield(shadow_file)
      @provider.should_receive(:safe_dscl).with("read /Users/toor GeneratedUID").and_return(uuid)
      @provider.should_receive(:safe_dscl).with("read /Users/toor").and_return("\nAuthenticationAuthority:\n")
      @provider.should_receive(:safe_dscl).with("append /Users/toor AuthenticationAuthority ';ShadowHash;'")
      @provider.modify_password
      shadow_file.string.should match(/^0{168}[0-9A-F]{48}0{1071}$/)
    end
  end

  describe "load_current_resource" do
    it "should raise an error if the required binary /usr/bin/dscl doesn't exist" do
      ::File.should_receive(:exists?).with("/usr/bin/dscl").and_return(false)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::User)
    end

    it "shouldn't raise an error if /usr/bin/dscl exists" do
      ::File.stub!(:exists?).and_return(true)
      lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exceptions::User)
    end
  end

  describe "when the user does not yet exist and chef is creating it" do
    context "with a numeric gid" do
      before do
        @new_resource.comment "#mockssuck"
        @new_resource.gid 1001
      end

      it "creates the user, comment field, sets uid, gid, configures the home directory, sets the shell, and sets the password" do
        @provider.should_receive :dscl_create_user
        @provider.should_receive :dscl_create_comment
        @provider.should_receive :set_uid
        @provider.should_receive :dscl_set_gid
        @provider.should_receive :modify_home
        @provider.should_receive :dscl_set_shell
        @provider.should_receive :modify_password
        @provider.create_user
      end

      it "creates the user and sets the comment field" do
        @provider.should_receive(:safe_dscl).with("create /Users/toor").and_return(true)
        @provider.dscl_create_user
      end

      it "sets the comment field" do
        @provider.should_receive(:safe_dscl).with("create /Users/toor RealName '#mockssuck'").and_return(true)
        @provider.dscl_create_comment
      end

      it "should run safe_dscl with create /Users/user PrimaryGroupID to set the users primary group" do
        @provider.should_receive(:safe_dscl).with("create /Users/toor PrimaryGroupID '1001'").and_return(true)
        @provider.dscl_set_gid
      end

      it "should run safe_dscl with create /Users/user UserShell to set the users login shell" do
        @provider.should_receive(:safe_dscl).with("create /Users/toor UserShell '/usr/bin/false'").and_return(true)
        @provider.dscl_set_shell
      end
    end

    context "with a non-numeric gid" do
      before do
        @new_resource.comment "#mockssuck"
        @new_resource.gid "newgroup"
      end

      it "should map the group name to a numeric ID when the group exists" do
        @provider.should_receive(:safe_dscl).with("read /Groups/newgroup PrimaryGroupID").ordered.and_return("PrimaryGroupID: 1001\n")
        @provider.should_receive(:safe_dscl).with("create /Users/toor PrimaryGroupID '1001'").ordered.and_return(true)
        @provider.dscl_set_gid
      end

      it "should raise an exception when the group does not exist" do
        shell_return = ShellCmdResult.new("<dscl_cmd> DS Error: -14136 (eDSRecordNotFound)", 'err', -14136)
        @provider.should_receive(:shell_out).with('dscl . -read /Groups/newgroup PrimaryGroupID').and_return(shell_return)
        lambda { @provider.dscl_set_gid }.should raise_error(Chef::Exceptions::GroupIDNotFound)
      end
    end
  end

  describe "when the user exists and chef is managing it" do
    before do
      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
      
      # These are all different from @current_resource
      @new_resource.username "mud"
      @new_resource.uid 2342
      @new_resource.gid 2342
      @new_resource.home '/Users/death'
      @new_resource.password 'goaway'
    end
    
    it "sets the user, comment field, uid, gid, moves the home directory, sets the shell, and sets the password" do
      @provider.should_receive :dscl_create_user
      @provider.should_receive :dscl_create_comment
      @provider.should_receive :set_uid
      @provider.should_receive :dscl_set_gid
      @provider.should_receive :modify_home
      @provider.should_receive :dscl_set_shell
      @provider.should_receive :modify_password
      @provider.create_user
    end
  end

  describe "when changing the gid" do
    before do
      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
      
      # This is different from @current_resource
      @new_resource.gid 2342
    end
    
    it "sets the gid" do
      @provider.should_receive :dscl_set_gid
      @provider.manage_user
    end
  end

  describe "when the user exists and chef is removing it" do
    it "removes the user's home directory when the resource is configured to manage home" do
      @new_resource.supports({ :manage_home => true })
      @provider.should_receive(:safe_dscl).with("read /Users/toor").and_return("NFSHomeDirectory: /Users/fuuuuuuuuuuuuu")
      @provider.should_receive(:safe_dscl).with("delete /Users/toor")
      FileUtils.should_receive(:rm_rf).with("/Users/fuuuuuuuuuuuuu")
      @provider.remove_user
    end
    
    it "removes the user from any group memberships" do
      Etc.stub(:group).and_yield(OpenStruct.new(:name => 'ragefisters', :mem => 'toor'))
      @provider.should_receive(:safe_dscl).with("delete /Users/toor")
      @provider.should_receive(:safe_dscl).with("delete /Groups/ragefisters GroupMembership 'toor'")
      @provider.remove_user
    end
  end

  describe "when discovering if a user is locked" do

    it "determines the user is not locked when dscl shows an AuthenticationAuthority without a DisabledUser field" do
      @provider.should_receive(:safe_dscl).with("read /Users/toor")
      @provider.should_not be_locked
    end

    it "determines the user is locked when dscl shows an AuthenticationAuthority with a DisabledUser field" do
      @provider.should_receive(:safe_dscl).with('read /Users/toor').and_return("\nAuthenticationAuthority: ;DisabledUser;\n")
      @provider.should be_locked
    end

    it "determines the user is not locked when dscl shows no AuthenticationAuthority" do
      @provider.should_receive(:safe_dscl).with('read /Users/toor').and_return("\n")
      @provider.should_not be_locked
    end
  end

  describe "when locking the user" do
    it "should run safe_dscl with append /Users/user AuthenticationAuthority ;DisabledUser; to lock the user account" do
      @provider.should_receive(:safe_dscl).with("append /Users/toor AuthenticationAuthority ';DisabledUser;'")
      @provider.lock_user
    end
  end

  describe "when unlocking the user" do
    it "removes DisabledUser from the authentication string" do
      @provider.should_receive(:safe_dscl).with("read /Users/toor AuthenticationAuthority").and_return("\nAuthenticationAuthority: ;ShadowHash; ;DisabledUser;\n")
      @provider.should_receive(:safe_dscl).with("create /Users/toor AuthenticationAuthority ';ShadowHash;'")
      @provider.unlock_user
    end
  end
end
