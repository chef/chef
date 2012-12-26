#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/config'
require 'chef/log'
require 'chef/resource/directory'
require 'chef/provider'
require 'chef/provider/file'
require 'fileutils'

class Chef
  class Provider
    class Directory < Chef::Provider::File

      include Chef::Mixin::EnforceOwnershipAndPermissions

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::Directory.new(@new_resource.name)
        @current_resource.path(@new_resource.path)
        load_current_resource_attrs
        setup_acl

        @current_resource
      end

      def define_resource_requirements
        # this must be evaluated before whyrun messages are printed
        access_controls.requires_changes?

        requirements.assert(:create) do |a|
          # Make sure the parent dir exists, or else fail.
          # for why run, print a message explaining the potential error.
          parent_directory = ::File.dirname(@new_resource.path)
          a.assertion { @new_resource.recursive || ::File.directory?(parent_directory) }
          a.failure_message(Chef::Exceptions::EnclosingDirectoryDoesNotExist, "Parent directory #{parent_directory} does not exist, cannot create #{@new_resource.path}")
          a.whyrun("Assuming directory #{parent_directory} would have been created")
        end

        requirements.assert(:create) do |a|
          parent_directory = ::File.dirname(@new_resource.path)
          a.assertion do
            if @new_resource.recursive
              # find the lowest-level directory in @new_resource.path that already exists
              # make sure we have write permissions to that directory
              is_parent_writable = lambda do |base_dir|
                base_dir = ::File.dirname(base_dir) 
                if ::File.exist?(base_dir) 
                  ::File.writable?(base_dir)
                else
                  is_parent_writable.call(base_dir)
                end
              end
              is_parent_writable.call(@new_resource.path)
            else
              # in why run mode & parent directory does not exist no permissions check is required
              # If not in why run, permissions must be valid and we rely on prior assertion that dir exists
              if !whyrun_mode? || ::File.exist?(parent_directory) 
                ::File.writable?(parent_directory)
              else
                true
              end
            end
          end
          a.failure_message(Chef::Exceptions::InsufficientPermissions, 
            "Cannot create #{@new_resource} at #{@new_resource.path} due to insufficient permissions")
        end

        requirements.assert(:delete) do |a| 
          a.assertion do 
            if ::File.exist?(@new_resource.path)
              ::File.directory?(@new_resource.path) && ::File.writable?(@new_resource.path) 
            else
              true
            end
          end
          a.failure_message(RuntimeError, "Cannot delete #{@new_resource} at #{@new_resource.path}!")
          # No why-run handling here: 
          #  * if we don't have permissions, this is unlikely to be changed earlier in the run
          #  * if the target is a file (not a dir), there's no reasonable path by which this would have been changed
        end
      end

      def action_create
        unless ::File.exist?(@new_resource.path)
          converge_by("create new directory #{@new_resource.path}") do 
            if @new_resource.recursive == true
              ::FileUtils.mkdir_p(@new_resource.path)
            else
              ::Dir.mkdir(@new_resource.path)
            end
            Chef::Log.info("#{@new_resource} created directory #{@new_resource.path}")
          end 
        end
        set_all_access_controls
      end

      def action_delete
        if ::File.exist?(@new_resource.path)
          converge_by("delete existing directory #{@new_resource.path}") do
            if @new_resource.recursive == true
              FileUtils.rm_rf(@new_resource.path)
              Chef::Log.info("#{@new_resource} deleted #{@new_resource.path} recursively")
            else
              ::Dir.delete(@new_resource.path)
              Chef::Log.info("#{@new_resource} deleted #{@new_resource.path}")
            end
          end
        end
      end
    end
  end
end
