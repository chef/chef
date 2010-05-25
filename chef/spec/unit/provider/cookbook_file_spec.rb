#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'ostruct'

describe Chef::Provider::CookbookFile do
  before do
    Chef::Config.cookbook_path(File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks")))
    Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest) }

    @node = Chef::Node.new
    @cookbook_collection = Chef::CookbookCollection.new(Chef::CookbookLoader.new)
    @run_context = Chef::RunContext.new(@node, @cookbook_collection)

    @new_resource = Chef::Resource::CookbookFile.new('apache2_module_conf_generate.pl')
    @new_resource.cookbook_name = 'apache2'
    @provider = Chef::Provider::CookbookFile.new(@new_resource, @run_context)

    @file_content=<<-EXPECTED
# apache2_module_conf_generate.pl
# this is just here for show.
EXPECTED

  end

  it "prefers the explicit cookbook name on the resource to the implicit one" do
    @new_resource.cookbook('nginx')
    @provider.resource_cookbook.should == 'nginx'
  end

  it "falls back to the implicit cookbook name on the resource" do
    @provider.resource_cookbook.should == 'apache2'
  end

  describe "when the file doesn't yet exist" do
    before do
      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
    end

    it "loads the current file state" do
      @provider.load_current_resource
      @provider.current_resource.checksum.should be_nil
    end

    it "looks up a file from the cookbook cache" do
      expected = CHEF_SPEC_DATA + "/cookbooks/apache2/files/default/apache2_module_conf_generate.pl"
      @provider.file_cache_location.should == expected
    end

    it "sets access controls on a file" do
      @new_resource.owner(0)
      @new_resource.group(0)
      @new_resource.mode(0400)
      ::File.should_receive(:stat).with('/tmp/foo').and_return(OpenStruct.new(:owner => 99, :group => 99, :mode => 0100444))
      FileUtils.should_receive(:chmod).with(0400, '/tmp/foo')
      FileUtils.should_receive(:chown).with(0, nil, '/tmp/foo')
      FileUtils.should_receive(:chown).with(nil, 0, '/tmp/foo')

      @provider.set_all_access_controls('/tmp/foo')
      @provider.new_resource.should be_updated
    end

    it "stages the cookbook to a temporary file" do
      cache_file_location = CHEF_SPEC_DATA + "/cookbooks/apache2/files/default/apache2_module_conf_generate.pl"
      actual = nil
      Tempfile.open('rspec-staging-test') do |staging|
        staging.close
        @provider.should_receive(:set_all_access_controls).with(staging.path)
        @provider.stage_file_to_tmpdir(staging.path)
        actual = IO.read(staging.path)
      end
      actual.should == @file_content
    end
    
    it "installs the file from the cookbook cache" do
      tempfile = nil
      begin
        tempfile = Tempfile.open('rspec-action-create-test')
        install_path = ::File.dirname(tempfile.path) + '/apache2_modconf.pl'
        @new_resource.path(install_path)
        @provider.should_receive(:set_all_access_controls)
        @provider.action_create
        actual = IO.read(install_path)
        actual.should == @file_content
      ensure
        tempfile && tempfile.close!
      end
    end
    
    it "installs the file for create_if_missing" do
      install_path = nil
      Tempfile.open('rspec-action-create-test') do |tempfile|
        install_path = ::File.dirname(tempfile.path) + '/apache2_modconf.pl'
        FileUtils.rm(install_path)
      end

      ::File.exist?(install_path).should be_false

      @new_resource.path(install_path)
      @provider.should_receive(:set_all_access_controls)
      @provider.action_create_if_missing
      actual = IO.read(install_path)
      actual.should == @file_content
    end
  end

  describe "when the file exists but has incorrect content" do
    before do
      @tempfile = Tempfile.open('cookbook_file_spec')
      @new_resource.path(@target_file = @tempfile.path)
      @tempfile.puts "the wrong content"
      @tempfile.close
      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
    end
    
    it "loads the current file state" do
      @provider.load_current_resource
      expected = "3d69d1b1c1c84ae32dc03456b8ea2ea1637471bc20eecd59251158f50f6b8a29"
      @provider.current_resource.checksum.should == expected
    end

    it "overwrites it when the create action is called" do
      @provider.should_receive(:set_all_access_controls)
      @provider.action_create
      actual = IO.read(@target_file)
      actual.should == @file_content
    end

    it "doesn't overwrite when the create if missing action is called" do
      @provider.should_not_receive(:set_all_access_controls)
      @provider.action_create_if_missing
      actual = IO.read(@target_file)
      actual.should == "the wrong content\n"
    end
    
    after { @tempfile && @tempfile.close! }
  end
  
  describe "when the file has the correct content" do
    before do
      @tempfile = Tempfile.open('cookbook_file_spec')
      @new_resource.path(@target_file = @tempfile.path)
      @tempfile.write(@file_content)
      @tempfile.close
      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
    end

    it "loads the current file state" do
      @provider.load_current_resource
      expected = "17fccd87e03f48f4312c9f8c1dd88cad98f0cf3a6fc68a8d922562c427ecb726"
      @provider.current_resource.checksum.should == expected
    end

    it "it checks access control but does not alter content when action is create" do
      pending(<<-FUUUU)

This test fails because the checksum method for Chef::Provider::File (from the
checksum mixin) generates sha2-256 checksums, but cookbooks are using MD5 now.
Something must give. Affected by this bug:
* load_current_resource for this class
* when C::P::RemoteFile delegates for deprecation to this class, it must happen
  in/before load_current_resource so the correct cksum implementation is used.
FUUUU
      
      pp :cb_file_chksum => @provider.checksum(CHEF_SPEC_DATA + "/cookbooks/apache2/files/default/apache2_module_conf_generate.pl")
      pp @provider.run_context.cookbook_collection['apache2']
      @provider.load_current_resource
      @provider.should_receive(:set_all_access_controls)
      @provider.should_not_receive(:stage_file_to_tmpdir)
      @provider.action_create
    end
    
    it "does not alter content or access control when action is create if missing" do
      pending
    end
  end
end

describe Chef::Provider::CookbookFile::FileAccessControl do
  before do
    @resource = Chef::Resource::File.new('/tmp/a_file.txt')
    @resource.owner('toor')
    @resource.group('wheel')
    @resource.mode('0400')
    @file_to_manage = '/tmp/different_file.txt'
    @fac = Chef::Provider::CookbookFile::FileAccessControl.new(@resource, @file_to_manage)
  end

  it "has a resource" do
    @fac.resource.should equal(@resource)
  end

  it "has a file to manage" do
    @fac.file.should == '/tmp/different_file.txt'
  end

  it "is not modified yet" do
    @fac.should_not be_modified
  end

  it "determines the uid of the owner specified by the resource" do
    Etc.should_receive(:getpwnam).with('toor').and_return(OpenStruct.new(:uid => 2342))
    @fac.target_uid.should == 2342
  end

  it "raises a Chef::Exceptions::UserIDNotFound error when Etc can't find the user's name" do
    Etc.should_receive(:getpwnam).with('toor').and_raise(ArgumentError)
    lambda { @fac.target_uid }.should raise_error(Chef::Exceptions::UserIDNotFound, "cannot resolve user id for 'toor'")
  end

  it "does not attempt to resolve the uid if the user is not specified" do
    resource = Chef::Resource::File.new("a file")
    fac = Chef::Provider::CookbookFile::FileAccessControl.new(resource, @file_to_manage)
    fac.target_uid.should be_nil
  end

  it "raises an ArgumentError if the resource's owner is set to something wack" do
    @resource.instance_variable_set(:@owner, :diaf)
    lambda { @fac.target_uid }.should raise_error(ArgumentError)
  end

  it "uses the resource's uid for the target uid when the resource's owner is specified by an integer" do
    @resource.owner(2342)
    @fac.target_uid.should == 2342
  end

  it "wraps uids to their negative complements to correctly handle negative uids" do
    # More: Mac OS X (at least) has negative UIDs for 'nobody' and some other
    # users. Ruby doesn't believe in negative UIDs so you get the dimished radix
    # complement (i.e., it wraps around the maximum size of C unsigned int) of these
    # uids. So we have to get ruby and negative uids to smoke the peace pipe
    # with each other.
    @resource.owner('nobody')
    Etc.should_receive(:getpwnam).with('nobody').and_return(OpenStruct.new(:uid => (4294967294)))
    @fac.target_uid.should == -2
  end

  it "sets the file's owner as specified in the resource when the current owner is incorrect" do
    @resource.owner(2342)
    @fac.stub!(:stat).and_return(OpenStruct.new(:uid => 1234))
    FileUtils.should_receive(:chown).with(2342, nil, '/tmp/different_file.txt')
    @fac.set_owner
    @fac.should be_modified
  end

  it "doesn't set the file's owner if it already matches" do
    @resource.owner(2342)
    @fac.stub!(:stat).and_return(OpenStruct.new(:uid => 2342))
    FileUtils.should_not_receive(:chown)
    @fac.set_owner
    @fac.should_not be_modified
  end

  it "determines the gid of the group specified by the resource" do
    Etc.should_receive(:getgrnam).with('wheel').and_return(OpenStruct.new(:gid => 2342))
    @fac.target_gid.should == 2342
  end

  it "uses a user specified gid as the gid" do
    @resource.group(2342)
    @fac.target_gid.should == 2342
  end

  it "raises a Chef::Exceptions::GroupIDNotFound error when Etc can't find the user's name" do
    Etc.should_receive(:getgrnam).with('wheel').and_raise(ArgumentError)
    lambda { @fac.target_gid }.should raise_error(Chef::Exceptions::GroupIDNotFound, "cannot resolve group id for 'wheel'")
  end

  it "does not attempt to resolve a gid when none is supplied" do
    resource = Chef::Resource::File.new('crab')
    fac = Chef::Provider::CookbookFile::FileAccessControl.new(resource, 'somefile')
    fac.target_gid.should be_nil
  end

  it "raises an error when the supplied group name is an alien" do
    @resource.instance_variable_set(:@group, :failburger)
    lambda { @fac.target_gid }.should raise_error(ArgumentError)
  end

  it "sets the file's group as specified in the resource when the group is not correct" do
    @resource.group(2342)
    @fac.stub!(:stat).and_return(OpenStruct.new(:gid => 815))
    FileUtils.should_receive(:chown).with(nil, 2342, '/tmp/different_file.txt')
    @fac.set_group
    @fac.should be_modified
  end

  it "doesnt set the file's group if it is already correct" do
    @resource.group(2342)
    @fac.stub!(:stat).and_return(OpenStruct.new(:gid => 2342))
    FileUtils.should_not_receive(:chown)
    @fac.set_group
    @fac.should_not be_modified
  end

  it "uses the supplied mode as octal when it's a string" do
    @resource.mode('444')
    @fac.target_mode.should == 292 # octal 444 => decimal 292
  end

  it "uses the supplied mode verbatim when it's an integer" do
    @resource.mode(00444)
    @fac.target_mode.should == 292
  end

  it "does not try to determine the mode when none is given" do
    resource = Chef::Resource::File.new('blahblah')
    fac = Chef::Provider::CookbookFile::FileAccessControl.new(resource, 'afile')
    fac.target_mode.should be_nil
  end

  it "sets the file's mode as specified in the resource when the current modes are incorrect" do
    # stat returns modes like 0100644 (octal) => 33188 (decimal)
    @fac.stub!(:stat).and_return(OpenStruct.new(:mode => 33188))
    FileUtils.should_receive(:chmod).with(256, '/tmp/different_file.txt')
    @fac.set_mode
    @fac.should be_modified
  end

  it "does not set the file's mode when the current modes are correct" do
    @fac.stub!(:stat).and_return(OpenStruct.new(:mode => 0100400))
    FileUtils.should_not_receive(:chmod)
    @fac.set_mode
    @fac.should_not be_modified
  end

  it "sets all access controls on a file" do
    @fac.stub!(:stat).and_return(OpenStruct.new(:owner => 99, :group => 99, :mode => 0100444))
    @resource.mode(0400)
    @resource.owner(0)
    @resource.group(0)
    FileUtils.should_receive(:chmod).with(0400, '/tmp/different_file.txt')
    FileUtils.should_receive(:chown).with(0, nil, '/tmp/different_file.txt')
    FileUtils.should_receive(:chown).with(nil, 0, '/tmp/different_file.txt')
    @fac.set_all
    @fac.should be_modified
  end

end