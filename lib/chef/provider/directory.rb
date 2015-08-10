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

      provides :directory

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::Directory.new(@new_resource.name)
        @current_resource.path(@new_resource.path)
        if !@new_resource.path.is_a?(Array) &&
           ::File.exists?(@current_resource.path) &&
           @action != :create_if_missing
          load_resource_attributes_from_file(@current_resource)
        end
        @current_resource
      end

      def define_resource_requirements
        # deep inside FAC we have to assert requirements, so call FACs hook to set that up
        access_controls.define_resource_requirements

        requirements.assert(:create) do |a|
          # Make sure the parent dir exists, or else fail.
          # for why run, print a message explaining the potential error.
          badpath = ''
          a.assertion do
            paths = @new_resource.path.is_a?(Array) ? @new_resource.path : [@new_resource.path]
            badpath = paths.find do |path|
              parent_directory = ::File.dirname(path)
              !@new_resource.recursive && !::File.directory?(parent_directory)
            end
            badpath.nil?
          end
          a.failure_message(Chef::Exceptions::EnclosingDirectoryDoesNotExist, "Parent directory #{badpath} does not exist, cannot create #{badpath}")
          a.whyrun("Assuming directory #{badpath} would have been created")
        end

        requirements.assert(:create) do |a|
          badpath = ''
          a.assertion do
            # We want to fail the assertion if *any* of the files are going to fail
            paths = @new_resource.path.is_a?(Array) ? @new_resource.path : [@new_resource.path]
            badpath = paths.find do |path|
              parent_directory = ::File.dirname(path)
              if @new_resource.recursive
                # find the lowest-level directory in @new_resource.path that already exists
                # make sure we have write permissions to that directory
                is_parent_writable = lambda do |base_dir|
                  base_dir = ::File.dirname(base_dir)
                  if ::File.exists?(base_dir)
                    Chef::FileAccessControl.writable?(base_dir)
                  else
                    is_parent_writable.call(base_dir)
                  end
                end
                !is_parent_writable.call(path)
              else
                # in why run mode & parent directory does not exist no permissions check is required
                # If not in why run, permissions must be valid and we rely on prior assertion that dir exists
                if !whyrun_mode? || ::File.exists?(parent_directory)
                  !Chef::FileAccessControl.writable?(parent_directory)
                end
              end
            end
            badpath.nil?
          end
          a.failure_message(Chef::Exceptions::InsufficientPermissions,
            "Cannot create #{@new_resource} at #{badpath} due to insufficient permissions")
        end

        requirements.assert(:delete) do |a|
          badpath = ''
          a.assertion do
            paths = @new_resource.path.is_a?(Array) ? @new_resource.path : [@new_resource.path]
            badpath = paths.find do |path|
              if ::File.exists?(path)
                !::File.directory?(path) || !Chef::FileAccessControl.writable?(path)
              end
            end
            badpath.nil?
          end
          a.failure_message(RuntimeError, "Cannot delete #{@new_resource} at #{badpath}!")
          # No why-run handling here:
          #  * if we don't have permissions, this is unlikely to be changed earlier in the run
          #  * if the target is a file (not a dir), there's no reasonable path by which this would have been changed
        end
      end

      def action_create
        paths = @new_resource.path.is_a?(Array) ? @new_resource.path : [@new_resource.path]
        paths.each do |path|
          unless ::File.exists?(path)
            converge_by("create new directory #{path}") do
              if @new_resource.recursive == true
                ::FileUtils.mkdir_p(path)
              else
                ::Dir.mkdir(path)
              end
              Chef::Log.info("#{@new_resource} created directory #{path}")
            end
          end
        end
        do_acl_changes
        do_selinux(true)

        # For now, we trample existing file permissions when working with a path array
        # because a) load_resource_attributes_from_file takes a resource as an argument
        # (which would be hard to provide here) and b) the logic might be confusing to
        # the end user.
        load_resource_attributes_from_file(@new_resource) unless @new_resource.path.is_a?(Array)
      end

      def action_delete
        paths = @new_resource.path.is_a?(Array) ? @new_resource.path : [@new_resource.path]
        paths.each do |path|
          if ::File.exists?(path)
            converge_by("delete existing directory #{path}") do
              if @new_resource.recursive == true
                FileUtils.rm_rf(path)
                Chef::Log.info("#{@new_resource} deleted #{path} recursively")
              else
                ::Dir.delete(path)
                Chef::Log.info("#{@new_resource} deleted #{path}")
              end
            end
          end
        end
      end

      private

      def managing_content?
        false
      end

    end
  end
end
