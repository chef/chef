#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

class PreferredFileTestHarness
  include Chef::Mixin::FindPreferredFile
end


describe Chef::Mixin::FindPreferredFile do
  
  before do
    @finder = PreferredFileTestHarness.new
    
    @default_file_list = %q{
/srv/chef/cookbooks/apache2/templates/default/mods/status.conf.erb
/srv/chef/cookbooks/apache2/templates/default/mods/fcgid.conf.erb
/srv/chef/cookbooks/apache2/templates/default/mods/alias.conf.erb
/srv/chef/cookbooks/apache2/templates/default/a2dismod.erb
/srv/chef/cookbooks/apache2/templates/default/mods/ssl.conf.erb
/srv/chef/cookbooks/apache2/templates/default/default-site.erb
/srv/chef/cookbooks/apache2/templates/default/web_app.conf.erb
/srv/chef/cookbooks/apache2/templates/default/mods/dir.conf.erb
/srv/chef/cookbooks/apache2/templates/default/port_apache.erb
/srv/chef/cookbooks/apache2/templates/default/charset.erb
/srv/chef/cookbooks/apache2/templates/default/moin.erb
/srv/chef/cookbooks/apache2/templates/default/mods/negotiation.conf.erb
/srv/chef/cookbooks/apache2/templates/default/mods/autoindex.conf.erb
/srv/chef/cookbooks/apache2/templates/default/mods/proxy.conf.erb
/srv/chef/cookbooks/apache2/templates/default/a2dissite.erb
/srv/chef/cookbooks/apache2/templates/default/mods/deflate.conf.erb
/srv/chef/cookbooks/apache2/templates/default/mods/setenvif.conf.erb
/srv/chef/cookbooks/apache2/templates/default/apache2.conf.erb
/srv/chef/cookbooks/apache2/templates/default/a2enmod.erb
/srv/chef/cookbooks/apache2/templates/default/mods/mime.conf.erb
/srv/chef/cookbooks/apache2/templates/default/security.erb
/srv/chef/cookbooks/apache2/templates/default/ports.conf.erb
/srv/chef/cookbooks/apache2/templates/default/a2ensite.erb}.strip.split("\n")
  end
  
  def default_file_hash
    hsh = {}
    @default_file_list.each do |filename|
      hsh[filename] = filename
    end
    hsh
  end
  
  describe "finding preferred files from the list" do
    
    it "finds the default file out of a list when nothing else matches" do
      @finder.stub!(:load_cookbook_files).and_return(default_file_hash)
      args = %w{no_cookbook_id no_filetype mods/deflate.conf.erb nohost.example.com noplatform noversion}
      @finder.find_preferred_file(*args).should == "/srv/chef/cookbooks/apache2/templates/default/mods/deflate.conf.erb"
    end

    it "finds the default file with brackets" do
      file_name = "file-with-[brackets]"
      expected_file_path = "/srv/chef/cookbooks/apache2/templates/default/#{file_name}"
      hsh = default_file_hash.merge({
         expected_file_path => expected_file_path 
      })
      @finder.stub!(:load_cookbook_files).and_return(hsh)
      args = %w{no_cookbook_id no_filetype} + [ file_name ] + %w{nohost.example.com noplatform noversion}
      @finder.find_preferred_file(*args).should == expected_file_path
    end
    
    it "prefers a platform specific file to the default" do
      @default_file_list << "/srv/chef/cookbooks/apache2/templates/ubuntu/mods/deflate.conf.erb"
      @finder.stub!(:load_cookbook_files).and_return(default_file_hash)
      args = %w{no_cookbook_id no_filetype mods/deflate.conf.erb nohost.example.com ubuntu noversion}
      @finder.find_preferred_file(*args).should == "/srv/chef/cookbooks/apache2/templates/ubuntu/mods/deflate.conf.erb"
    end

    it "prefers a platform + version specific file to the default or platform specific version" do
      @default_file_list << "/srv/chef/cookbooks/apache2/templates/ubuntu/mods/deflate.conf.erb"
      @default_file_list << "/srv/chef/cookbooks/apache2/templates/ubuntu-8.04/mods/deflate.conf.erb"
      @finder.stub!(:load_cookbook_files).and_return(default_file_hash)
      args = %w{no_cookbook_id no_filetype mods/deflate.conf.erb nohost.example.com ubuntu 8.04}
      @finder.find_preferred_file(*args).should == "/srv/chef/cookbooks/apache2/templates/ubuntu-8.04/mods/deflate.conf.erb"
    end

    it "prefers a host specific file to any other" do
      @default_file_list << "/srv/chef/cookbooks/apache2/templates/ubuntu/mods/deflate.conf.erb"
      @default_file_list << "/srv/chef/cookbooks/apache2/templates/ubuntu-8.04/mods/deflate.conf.erb"
      @default_file_list << "/srv/chef/cookbooks/apache2/templates/host-foo.example.com/mods/deflate.conf.erb"
      @finder.stub!(:load_cookbook_files).and_return(default_file_hash)
      args = %w{no_cookbook_id no_filetype mods/deflate.conf.erb foo.example.com ubuntu 8.04}
      @finder.find_preferred_file(*args).should == "/srv/chef/cookbooks/apache2/templates/host-foo.example.com/mods/deflate.conf.erb"
    end
    
    it "raises an error when no file can be found" do
      @finder.stub!(:load_cookbook_files).and_return(default_file_hash)
      args = %w{no_cookbook_id no_filetype mods/me_no_findy.erb nohost.example.com noplatform noversion}
      lambda { @finder.find_preferred_file(*args) }.should raise_error(Chef::Exceptions::FileNotFound)
    end

  end
  
end
