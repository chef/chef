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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::User::Dscl, "dscl" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group", :null_object => true, :group_name => "aj")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @status = mock("Process::Status", :null_object => true, :exitstatus => 0) 
    @pid = mock("PID", :null_object => true)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @stdout.stub!(:each).and_yield("\n")
    @stderr.stub!(:each).and_yield("")
    @provider.stub!(:popen4).and_yield(@pid,@stdin,@stdout,@stderr).and_return(@status)
  end
  
  it "should run popen4 with the supplied array of arguments appended to the dscl command" do
    @provider.should_receive(:popen4).with("dscl . -cmd /Path arg1 arg2")
    @provider.dscl("cmd", "/Path", "arg1", "arg2")
  end

  it "should return an array of four elements - cmd, status, stdout, stderr" do
    dscl_retval = @provider.dscl("cmd /Path args")
    dscl_retval.should be_a_kind_of(Array)
    dscl_retval.should == ["dscl . -cmd /Path args",@status,"\n",""]
  end
end

describe Chef::Provider::User::Dscl, "safe_dscl" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group", :null_object => true, :group_name => "aj")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @status = mock("Process::Status", :null_object => true, :exitstatus => 0)
    @provider.stub!(:dscl).and_return(["cmd", @status, "stdout", "stderr"])
  end
 
  it "should run dscl with the supplied cmd /Path args" do
    @provider.should_receive(:dscl).with("cmd /Path args")
    @provider.safe_dscl("cmd /Path args")
  end

  describe "with the dscl command returning a non zero exit status for a delete" do
    before do
      @status = mock("Process::Status", :null_object => true, :exitstatus => 1)
      @provider.stub!(:dscl).and_return(["cmd", @status, "stdout", "stderr"])
    end

    it "should return an empty string of standard output for a delete" do
      safe_dscl_retval = @provider.safe_dscl("delete /Path args")
      safe_dscl_retval.should be_a_kind_of(String)
      safe_dscl_retval.should == ""
    end

    it "should raise an exception for any other command" do
      lambda { @provider.safe_dscl("cmd /Path arguments") }.should raise_error(Chef::Exceptions::User)
    end
  end

  describe "with the dscl command returning no such key" do
    before do
      # @status = mock("Process::Status", :null_object => true, :exitstatus => 0)
      @provider.stub!(:dscl).and_return(["cmd", @status, "No such key: ", "stderr"])
    end

    it "should raise an exception" do
      lambda { @provider.safe_dscl("cmd /Path arguments") }.should raise_error(Chef::Exceptions::User)
    end
  end
 
  describe "with the dscl command returning a zero exit status" do
    it "should return the third array element, the string of standard output" do
      safe_dscl_retval = @provider.safe_dscl("cmd /Path args")
      safe_dscl_retval.should be_a_kind_of(String)
      safe_dscl_retval.should == "stdout"
    end
  end
end

describe Chef::Provider::User::Dscl, "get_free_uid" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "aj")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:safe_dscl).and_return("\naj      200\njt      201\n")
  end
  
  it "should run safe_dscl with list /Users uid" do
    @provider.should_receive(:safe_dscl).with("list /Users uid")
    @provider.get_free_uid
  end

  it "should return the first unused uid number on or above 200" do
    @provider.get_free_uid.should equal(202)
  end
  
  it "should raise an exception when the search limit is exhausted" do
    search_limit = 1
    lambda { @provider.get_free_uid(search_limit) }.should raise_error(RuntimeError)
  end
end

describe Chef::Provider::User::Dscl, "uid_used?" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "aj")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
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

describe Chef::Provider::User::Dscl, "set_uid" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => "abracadabra",
      :updated => nil
    )
    @current_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => "abracadabra",
      :updated => nil
    )
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:get_free_uid).and_return(501)
    @provider.stub!(:uid_used?).and_return(false)
    @provider.stub!(:safe_dscl).and_return(true)
  end

  describe "with the new resource and a uid number which is already in use" do
    before do
      @provider.stub!(:uid_used?).and_return(true)
    end

    it "should raise an exception if the new resources uid is already in use" do
      lambda { @provider.set_uid }.should raise_error(Chef::Exceptions::User)
    end
  end
  
  describe "with no uid number for the new resources" do
    before do
      @new_resource = mock("Chef::Resource::User",
        :null_object => true,
        :username => "adam",
        :uid => nil
      )
      @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
      @provider.stub!(:get_free_uid).and_return(501)
      @provider.stub!(:uid_used?).and_return(false)
      @provider.stub!(:safe_dscl).and_return(true)
    end

    it "should run get_free_uid and return a valid, unused uid number" do
      @provider.should_receive(:get_free_uid).and_return(501)
      @provider.set_uid
    end
  end

  describe "with blank uid number for the new resources" do
    before do
      @new_resource = mock("Chef::Resource::User",
        :null_object => true,
        :username => "adam",
        :uid => ""
      )
      @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
      @provider.stub!(:get_free_uid).and_return(501)
      @provider.stub!(:uid_used?).and_return(false)
      @provider.stub!(:safe_dscl).and_return(true)
    end

    it "should run get_free_uid and return a valid, unused uid number" do
      @provider.should_receive(:get_free_uid).and_return(501)
      @provider.set_uid
    end
  end

  describe "with a valid uid number which is not already in use" do
    it "should run safe_dscl with create /Users/user UniqueID uid" do
      @provider.should_receive(:safe_dscl).with("create /Users/adam UniqueID 1000").and_return(true)
      @provider.set_uid
    end
  end
end

describe Chef::Provider::User::Dscl, "modify_home" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @current_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :home => "/old/home/adam",
      :supports => { :manage_home => false }
    )
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :home => "/new/home/adam",
      :supports => { :manage_home => false }
    )
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:safe_dscl).and_return(true)
    File.stub!(:exists?).and_return(false,false,true)
    @provider.stub!(:run_command).and_return(true)
    FileUtils.stub!(:rmdir).and_return(true)
    FileUtils.stub!(:chown_R).and_return(true)
  end

  describe "with no home for the new resources" do
    before do
      @new_resource = mock("Chef::Resource::User",
        :null_object => true,
        :username => "adam",
        :home => nil,
        :supports => { :manage_home => false }
      )
      @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
      @provider.current_resource = @current_resource
    end
  
    it "should run safe_dscl delete /Users/user NFSHomeDirectory" do
      @provider.should_receive(:safe_dscl).with("delete /Users/adam NFSHomeDirectory").and_return(true)
      @provider.modify_home
    end
  end
  
  describe "with blank home for the new resources" do
    before do
      @new_resource = mock("Chef::Resource::User",
        :null_object => true,
        :username => "adam",
        :home => "",
        :supports => { :manage_home => false }
      )
      @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
      @provider.current_resource = @current_resource
    end
  
    it "should run safe_dscl delete /Users/user NFSHomeDirectory" do
      @provider.should_receive(:safe_dscl).with("delete /Users/adam NFSHomeDirectory").and_return(true)
      @provider.modify_home
    end
  end

  describe "with a home specified in the new resource and manage_home set to true" do
    before do
      @new_resource.stub!(:supports).and_return({ :manage_home => true })
    end
  
    describe "with an invalid path spec" do
      before do
        @current_resource = mock("Chef::Resource::User",
          :null_object => true,
          :username => "adam",
          :home => "/old/home/adam",
          :supports => { :manage_home => false }
        )
        @new_resource = mock("Chef::Resource::User",
          :null_object => true,
          :username => "adam",
          :home => "a path with no leading slash",
          :supports => { :manage_home => false }
        )
        @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
        @provider.current_resource = @current_resource
      end

      it "should raise an exception" do
        lambda { @provider.modify_home }.should raise_error
      end
    end
  
    it "should move the current resources home directory to the new path if it existed" do
      File.stub!(:exists?).and_return(true,false)
      Dir.stub!(:glob).and_return(["/old/home/adam/.dotfile","/old/home/adam/file"])
      FileUtils.stub!(:mv).and_return(true)
      FileUtils.stub!(:mkdir_p).and_return(true)
      FileUtils.stub!(:rmdir).and_return(true)
      
      File.should_receive(:exists?).and_return(true,false)
      Dir.should_receive(:glob).and_return(["/old/home/adam/.dotfile","/old/home/adam/file"])
      FileUtils.should_receive(:mv).and_return(true)
      @provider.modify_home
    end
  
    it "should raise an exception when the systems user template dir (skel) cannot be found" do
      ::File.stub!(:exists?).and_return(false,false,false)
      lambda { @provider.modify_home }.should raise_error(Chef::Exceptions::User)
    end
  
    it "should run ditto to copy any missing files from skel to the new home dir" do
      @provider.should_receive(:run_command).with({ :command => "ditto '/System/Library/User Template/English.lproj' '/new/home/adam'" }).and_return(true)
      @provider.modify_home
    end
  end

  it "should run safe_dscl with create /Users/user NFSHomeDirectory and with the new resources home directory" do
    @provider.should_receive(:safe_dscl).with("create /Users/adam NFSHomeDirectory '/new/home/adam'").and_return(true)
    @provider.modify_home
  end
end

describe Chef::Provider::User::Dscl, "osx_shadow_hash?" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "adam")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:safe_dscl).and_return(true)
  end

  it "should return true when the string is a shadow hash" do
    @provider.osx_shadow_hash?("0"*8*155).should eql(true)
  end

  it "should return false otherwise" do
    @provider.osx_shadow_hash?("any other string").should eql(false)
  end
end

describe Chef::Provider::User::Dscl, "osx_salted_sha1?" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "adam")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:safe_dscl).and_return(true)
  end

  it "should return true when the string is a salted sha1" do
    @provider.osx_salted_sha1?("0"*48).should eql(true)
  end

  it "should return false otherwise" do
    @provider.osx_salted_sha1?("any other string").should eql(false)
  end
end

describe Chef::Provider::User::Dscl, "guid" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "adam")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:safe_dscl).and_return("GeneratedUID: 2B503067-BA65-47F3-B2B7-BE321E618CEA\n")
  end

  it "should run safe_dscl with read /Users/user GeneratedUID to get the users GUID" do
    @provider.should_receive(:safe_dscl).with("read /Users/adam GeneratedUID")
    @provider.guid
  end
end

describe Chef::Provider::User::Dscl, "shadow_hash_set?" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "adam")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:safe_dscl).and_return("\n\n")
  end

  it "should run safe_dscl with read /Users/user to see if the AuthenticationAuthority key exists" do
    @provider.should_receive(:safe_dscl).with("read /Users/adam")
    @provider.shadow_hash_set?
  end

  describe "with a user account and AuthenticationAuthority key exists" do
    before do
      @provider.stub!(:safe_dscl).and_return("\nAuthenticationAuthority: \n")
    end
    
    it "should run safe_dscl with read /Users/user AuthenticationAuthority to see if the account authorization scheme is set to shadow hash" do
      @provider.should_receive(:safe_dscl).with("read /Users/adam AuthenticationAuthority")
      @provider.shadow_hash_set?.should eql(false)
    end

    describe "with a ShadowHash field in the AuthenticationAuthority key" do
      before do
        @provider.stub!(:safe_dscl).and_return("\nAuthenticationAuthority: ;ShadowHash;\n")
      end
      it "should return true" do
        @provider.shadow_hash_set?.should eql(true)
      end
    end

    describe "with no ShadowHash field in the AuthenticationAuthority key" do
      before do
        @provider.stub!(:safe_dscl).and_return("\nAuthenticationAuthority: \n")
      end
      it "should return false" do
        @provider.shadow_hash_set?.should eql(false)
      end
    end
  end

  describe "with no AuthenticationAuthority key in the user account" do
    it "should return false" do
      @provider.shadow_hash_set?.should eql(false)
    end
  end
end

describe Chef::Provider::User::Dscl, "modify_password" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :password => "password"
    )
    @new_resource.stub!(:to_s).and_return("user[adam]")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @output = mock("File", :null_object => true)
    @output.stub!(:puts).and_return(true)
    File.stub!(:open).and_yield(@output).and_return(true)
    Kernel.stub!(:rand).and_return(15) # 'F'
    OpenSSL::Digest::SHA1.stub!(:hexdigest).and_return("SHA1-"*8)
    @provider.stub!(:shadow_hash_set?).and_return(false)
    @provider.stub!(:safe_dscl).and_return("")
    @provider.stub!(:guid).and_return("2B503067-BA65-47F3-B2B7-BE321E618CEA")
  end

  it "should log an appropriate message" do
    Chef::Log.should_receive(:debug).with("user[adam]: updating password")
    @provider.modify_password
  end
  
  describe "with a salted sha1 for the password" do
    before(:each) do
      @new_resource.stub!(:password).and_return("F"*48)
    end
    
    it "should write a shadow hash file with the expected salted sha1" do
      expected_salted_sha1 = @new_resource.password
      expected_shadow_hash = "00000000"*155
      expected_shadow_hash[168] = expected_salted_sha1
      @output.should_receive(:puts).with(expected_shadow_hash)
      @provider.modify_password
    end    
  end

  describe "with a shadow hash file for the password" do
    before(:each) do
      @new_resource.stub!(:password).and_return("F"*1240)
    end
    
    it "should write the shadow hash file directly to /var/db/shadow/hash/GUID" do
      expected_shadow_hash = @new_resource.password
      @output.should_receive(:puts).with(expected_shadow_hash)
      @provider.modify_password
    end
  end

  describe "with any other string for the password" do
    before(:each) do
      @new_resource.stub!(:password).and_return("password")
    end
    
    it "should output a salted sha1 and shadow hash file from the specified password" do
      expected_salted_sha1 = "F"*8+"SHA1-"*8
      expected_shadow_hash = "00000000"*155
      expected_shadow_hash[168] = expected_salted_sha1
      OpenSSL::Digest::SHA1.should_receive(:hexdigest).with("\377\377\377\377password")
      @output.should_receive(:puts).with(expected_shadow_hash)
      @provider.modify_password
    end    
  end

  it "should write the output directly to the shadow hash file at /var/db/shadow/hash/GUID" do
    File.should_receive(:open).with("/var/db/shadow/hash/2B503067-BA65-47F3-B2B7-BE321E618CEA",'w',0600)
    @provider.modify_password
  end

  it "should run safe_dscl append /Users/user AuthenticationAuthority ;ShadowHash; when no shadow hash set" do
    @provider.should_receive(:safe_dscl).with("append /Users/adam AuthenticationAuthority ';ShadowHash;'")
    @provider.modify_password
  end
end

describe Chef::Provider::User::Dscl, "load_current_resource" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "adam")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    File.stub!(:exists?).and_return(false)
  end

  it "should raise an error if the required binary /usr/bin/dscl doesn't exist" do
    File.should_receive(:exists?).with("/usr/bin/dscl").and_return(false)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::User)
  end

  it "shouldn't raise an error if /usr/bin/dscl exists" do
    File.stub!(:exists?).and_return(true)
    lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exceptions::User)
  end
end

describe Chef::Provider::User::Dscl, "create_user" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true)
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:manage_user).and_return(true)
  end

  it "should run manage_user with manage=false to create all the user attributes" do
    @provider.should_receive(:manage_user).with(false).and_return(true)
    @provider.create_user
  end
end

describe Chef::Provider::User::Dscl, "manage_user" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => "abracadabra",
      :updated => nil
    )
    @current_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => "abracadabra",
      :updated => nil
    )
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:safe_dscl).and_return(true)
    @provider.stub!(:set_uid).and_return(true)
    @provider.stub!(:modify_home).and_return(true)
    @provider.stub!(:modify_password).and_return(true)
  end

  fields = [:username,:comment,:uid,:gid,:home,:shell,:password]
  fields.each do |field|
    it "should check for differences in #{field.to_s} between the current and new resources" do
        @new_resource.should_receive(field)
        @current_resource.should_receive(field)
        @provider.manage_user
    end

    it "should manage the #{field} if it changed and the new resources #{field} is not null" do
      @current_resource.stub!(field).and_return("oldval")
      @new_resource.stub!(field).and_return("newval")
      @current_resource.should_receive(field).once
      @new_resource.should_receive(field).twice
      @provider.manage_user
    end
  end

  describe "with manage set to false" do
    before do
      @node = mock("Chef::Node", :null_object => true)
      @new_resource = mock("Chef::Resource::User",
        :null_object => true,
        :username => "adam",
        :comment => "Adam Jacob",
        :uid => 1000,
        :gid => 1000,
        :home => "/home/adam",
        :shell => "/usr/bin/zsh",
        :password => "abracadabra",
        :updated => nil
      )
      @current_resource = mock("Chef::Resource::User",
        :null_object => true,
        :username => "adam",
        :comment => "Adam Jacob",
        :uid => 1000,
        :gid => 1000,
        :home => "/home/adam",
        :shell => "/usr/bin/zsh",
        :password => "abracadabra",
        :updated => nil
      )
      @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
      @provider.current_resource = @current_resource
      @provider.stub!(:safe_dscl).and_return(true)
      @provider.stub!(:set_uid).and_return(true)
      @provider.stub!(:modify_home).and_return(true)
      @provider.stub!(:modify_password).and_return(true)
    end

    it "should run safe_dscl with create /Users/user and with the new resources username" do
      @provider.should_receive(:safe_dscl).with("create /Users/adam").and_return(true)
      @provider.manage_user(false)
    end

    it "should run safe_dscl with create /Users/user RealName to set the users comment field" do
      @provider.should_receive(:safe_dscl).with("create /Users/adam RealName 'Adam Jacob'").and_return(true)
      @provider.manage_user(false)
    end

    it "should run set_uid to set the uid number" do
      @provider.should_receive(:set_uid).and_return(true)
      @provider.manage_user(false)
    end

    it "should run safe_dscl with create /Users/user PrimaryGroupID to set the users primary group" do
      @provider.should_receive(:safe_dscl).with("create /Users/adam PrimaryGroupID '1000'").and_return(true)
      @provider.manage_user(false)
    end

    it "should run modify_home to set the users home directory" do
      @provider.should_receive(:modify_home).and_return(true)
      @provider.manage_user(false)
    end

    it "should run safe_dscl with create /Users/user UserShell to set the users login shell" do
      @provider.should_receive(:safe_dscl).with("create /Users/adam UserShell '/usr/bin/zsh'").and_return(true)
      @provider.manage_user(false)
    end

    it "should run modify_password to set the users password or shadow hash" do
      @provider.should_receive(:modify_password).and_return(true)
      @provider.manage_user(false)
    end
  end
end

describe Chef::Provider::User::Dscl, "remove_user" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :supports => { :manage_home => false }
    )
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:safe_dscl).and_return("NFSHomeDirectory: users home dir")
    
    @group1 = mock("Struct::Group", 
      :null_object => false, 
      :name => "group1",
      :passwd => "*",
      :gid => 50,
      :mem => ["user1"]
    )
    @group2 = mock("Struct::Group", 
      :null_object => false, 
      :name => "group2",
      :passwd => "*",
      :gid => 50,
      :mem => ["user2", "adam"]
    )
    @group = mock("Struct::Group", :null_object => true)    
    Etc.stub!(:group).and_yield(@group1).and_yield(@group2).and_return(true)
    FileUtils.stub(:rm_rf).and_return(true)
  end
  
  it "should run rm_rf on the new resources home directory if manage_home is true" do
    @new_resource.stub!(:supports).and_return({ :manage_home => true })
    @provider.should_receive(:safe_dscl).with("read /Users/adam")
    @provider.should_receive(:safe_dscl).with("read /Users/adam NFSHomeDirectory")
    FileUtils.should_receive(:rm_rf).with("users home dir").and_return(true)
    @provider.remove_user
  end
    
  it "should run safe_dscl with delete /Groups/group GroupMembership and with the new resources username" do
    @provider.should_receive(:safe_dscl).with("delete /Groups/group2 GroupMembership 'adam'").and_return(true)
    @provider.remove_user
  end

  it "should run safe_dscl with delete /Users/user and with the new resources username" do
    @provider.should_receive(:safe_dscl).with("delete /Users/adam").and_return(true)
    @provider.remove_user
  end
end

describe Chef::Provider::User::Dscl, "locked?" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "adam")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:safe_dscl).and_return("\n\n")
  end

  it "should run safe_dscl with read /Users/user to see if the AuthenticationAuthority key exists" do
    @provider.should_receive(:safe_dscl).with("read /Users/adam")
    @provider.locked?
  end

  describe "with a user account and AuthenticationAuthority key exists" do
    before do
      @provider.stub!(:safe_dscl).and_return("\nAuthenticationAuthority: \n")
    end
    
    it "should run safe_dscl with read /Users/user AuthenticationAuthority to see if the account is disabled" do
      @provider.should_receive(:safe_dscl).with("read /Users/adam AuthenticationAuthority")
      @provider.locked?.should eql(false)
    end

    describe "with a DisabledUser field in the AuthenticationAuthority key" do
      before do
        @provider.stub!(:safe_dscl).and_return("\nAuthenticationAuthority: ;DisabledUser;\n")
      end
      it "should return true" do
        @provider.locked?.should eql(true)
      end
    end

    describe "with no DisabledUser field in the AuthenticationAuthority key" do
      before do
        @provider.stub!(:safe_dscl).and_return("\nAuthenticationAuthority: \n")
      end
      it "should return false" do
        @provider.locked?.should eql(false)
      end
    end
  end

  describe "with no AuthenticationAuthority key in the user account" do
    it "should return false" do
      @provider.locked?.should eql(false)
    end
  end
end

describe Chef::Provider::User::Dscl, "check_lock" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "adam")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:locked?).and_return("retval")
  end

  it "should run locked? and return its value" do
    @provider.should_receive(:locked?)
    @provider.check_lock.should == "retval"
  end
end

describe Chef::Provider::User::Dscl, "lock_user" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "adam")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:safe_dscl).and_return(true)
  end
  
  it "should run safe_dscl with append /Users/user AuthenticationAuthority ;DisabledUser; to lock the user account" do
    @provider.should_receive(:safe_dscl).with("append /Users/adam AuthenticationAuthority ';DisabledUser;'")
    @provider.lock_user
  end
end

describe Chef::Provider::User::Dscl, "unlock_user" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "adam")
    @provider = Chef::Provider::User::Dscl.new(@node, @new_resource)
    @provider.stub!(:safe_dscl).and_return("AuthenticationAuthority: ;DisabledUser;")
  end
  
  it "should run safe_dscl with read /Users/user AuthenticationAuthority to get the whole authentication string" do
    @provider.should_receive(:safe_dscl).with("read /Users/adam AuthenticationAuthority")
    @provider.unlock_user
  end

  it "should run safe_dscl with create /Users/user AuthenticationAuthority to re-write without ;DisabledUser; substring" do
    @provider.should_receive(:safe_dscl).with("create /Users/adam AuthenticationAuthority ''")
    @provider.unlock_user
  end
end
