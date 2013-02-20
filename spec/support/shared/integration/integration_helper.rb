#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Author:: Ho-Sheng Hsiao (<hosh@opscode.com>)
# Copyright:: Copyright (c) 2012, 2013 Opscode, Inc.
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

require 'tmpdir'
require 'fileutils'
require 'chef_zero/rspec'
require 'chef/config'
require 'json'
require 'support/shared/integration/knife_support'
require 'spec_helper'

module IntegrationSupport
  include ChefZero::RSpec

  # Common layouts
  def one_of_each_resource_in_chef_server
    client 'x', '{}'
    cookbook 'x', '1.0.0', { 'metadata.rb' => ['name "x"', 'version "1.0.0"'].join("\n") }
    data_bag 'x', { 'y' => '{}' }
    environment 'x', '{}'
    node 'x', '{}'
    role 'x', '{}'
    user 'x', '{}'
  end

  def one_of_each_resource_in_repository(options = {})
    file 'clients/x.json', <<EOM
{}
EOM
    if metadata[:versioned_cookbooks]
      file 'cookbooks/x-1.0.0/metadata.rb', ['name "x"', 'version "1.0.0"'].join("\n")
    else
      file 'cookbooks/x/metadata.rb', [ 'name "x"', 'version "1.0.0"'].join("\n")
    end

    file 'data_bags/x/y.json', <<EOM
{
  "id": "y"
}
EOM
    file 'environments/_default.json', <<EOM
{
  "name": "_default",
  "description": "The default Chef environment",
  "cookbook_versions": {
  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {
  },
  "override_attributes": {
  }
}
EOM
    file 'environments/x.json', <<EOM
{
  "chef_type": "environment",
  "cookbook_versions": {
  },
  "default_attributes": {
  },
  "description": "",
  "json_class": "Chef::Environment",
  "name": "x",
  "override_attributes": {
  }
}
EOM
    file 'nodes/x.json', <<EOM
{}
EOM
    file 'roles/x.json', <<EOM
{
  "chef_type": "role",
  "default_attributes": {
  },
  "description": "",
  "env_run_lists": {
  },
  "json_class": "Chef::Role",
  "name": "x",
  "override_attributes": {
  },
  "run_list": [

  ]
}
EOM
    file 'users/x.json', <<EOM
{}
EOM
  end

  def extra_resources_in_repository
      # Extra files not found in the standard resource set
      file 'clients/y.json', { 'name' => 'y' }
      if metadata[:versioned_cookbooks]
        file 'cookbooks/x-1.0.0/blah.rb', ''
        file 'cookbooks/x-2.0.0/metadata.rb', ['name "x"', 'version "2.0.0"'].join("\n")
        file 'cookbooks/y-1.0.0/metadata.rb', ['name "y"', 'version "1.0.0"'].join("\n")
      else
        file 'cookbooks/x/blah.rb', ''
        file 'cookbooks/y/metadata.rb', ['name "y"', 'version "1.0.0"'].join("\n")
      end
      file 'data_bags/x/z.json', <<EOM
{
  "id": "z"
}
EOM
      file 'data_bags/y/zz.json', <<EOM
{
  "id": "zz"
}
EOM
      file 'environments/y.json', <<EOM
{
  "chef_type": "environment",
  "cookbook_versions": {
  },
  "default_attributes": {
  },
  "description": "",
  "json_class": "Chef::Environment",
  "name": "y",
  "override_attributes": {
  }
}
EOM
      file 'nodes/y.json', { 'name' => 'y' }
      file 'roles/y.json', <<EOM
{
  "chef_type": "role",
  "default_attributes": {
  },
  "description": "",
  "env_run_lists": {
  },
  "json_class": "Chef::Role",
  "name": "y",
  "override_attributes": {
  },
  "run_list": [

  ]
}
EOM
      file 'users/y.json', { 'name' => 'y' }
  end


  # Integration DSL

  def when_the_repository(description, *args, &block)
    context "When the local repository #{description}", *args do
      before :each do
        raise "Can only create one directory per test" if @repository_dir
        @repository_dir = Dir.mktmpdir('chef_repo')
        @old_chef_repo_path = Chef::Config.chef_repo_path
        @old_paths = {}
        Chef::Config.chef_repo_path = @repository_dir
        %w(client cookbook data_bag environment node role user).each do |object_name|
          @old_paths[object_name] = Chef::Config["#{object_name}_path".to_sym]
          Chef::Config["#{object_name}_path".to_sym] = nil
        end
      end

      after :each do
        if @repository_dir
          begin
            %w(client cookbook data_bag environment node role user).each do |object_name|
              Chef::Config["#{object_name}_path".to_sym] = @old_paths[object_name]
            end
            Chef::Config.chef_repo_path = @old_chef_repo_path
            FileUtils.remove_entry_secure(@repository_dir)
          ensure
            @old_chef_repo_path = nil
            @old_paths = nil
            @repository_dir = nil
          end
        end
      end

      def directory(relative_path, &block)
        old_parent_path = @parent_path
        @parent_path = path_to(relative_path)
        FileUtils.mkdir_p(@parent_path)
        instance_eval(&block) if block
        @parent_path = old_parent_path
      end

      def file(relative_path, contents)
        filename = path_to(relative_path)
        dir = File.dirname(filename)
        FileUtils.mkdir_p(dir) unless dir == '.'
        File.open(filename, 'w') do |file|
          raw = case contents
                when Hash
                  JSON.pretty_generate(contents)
                when Array
                  contents.join("\n")
                else
                  contents
                end
          file.write(raw)
        end
      end

      def symlink(relative_path, relative_dest)
        filename = path_to(relative_path)
        dir = File.dirname(filename)
        FileUtils.mkdir_p(dir) unless dir == '.'
        dest_filename = path_to(relative_dest)
        File.symlink(dest_filename, filename)
      end

      def path_to(relative_path)
        File.expand_path(relative_path, (@parent_path || @repository_dir))
      end

      def self.path_to(relative_path)
        File.expand_path(relative_path, (@parent_path || @repository_dir))
      end

      def self.directory(relative_path, &block)
        before :each do
          directory(relative_path, &block)
        end
      end

      def self.file(relative_path, contents)
        before :each do
          file(relative_path, contents)
        end
      end

      def self.symlink(relative_path, relative_dest)
        before :each do
          symlink(relative_path, relative_dest)
        end
      end

      def self.cwd(relative_path)
        before :each do
          @old_cwd = Dir.pwd
          Dir.chdir(path_to(relative_path))
        end
        after :each do
          Dir.chdir(@old_cwd)
        end
      end

      instance_eval(&block)
    end
  end

  # Versioned cookbooks

  def with_versioned_cookbooks(_metadata = {}, &block)
    _m = { :versioned_cookbooks => true }.merge(_metadata)
    context 'with versioned cookbooks', _m do
      before(:each) { Chef::Config[:versioned_cookbooks] = true }
      after(:each)  { Chef::Config[:versioned_cookbooks] = false }
      instance_eval(&block)
    end
  end

  def without_versioned_cookbooks(_metadata = {}, &block)
    _m = { :versioned_cookbooks => false }.merge(_metadata)
    context 'with versioned cookbooks', _m do
      # Just make sure this goes back to default
      before(:each) { Chef::Config[:versioned_cookbooks] = false }
      instance_eval(&block)
    end
  end

  def with_all_types_of_repository_layouts(&block)
    without_versioned_cookbooks(&block)
    with_versioned_cookbooks(&block)
  end
end
