#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/config"
require "chef/log"
require "chef/mixin/file_class"
require "chef/resource/link"
require "chef/provider"
require "chef/scan_access_control"
require "chef/util/path_helper"

class Chef
  class Provider
    class Link < Chef::Provider

      provides :link

      include Chef::Mixin::EnforceOwnershipAndPermissions
      include Chef::Mixin::FileClass

      def negative_complement(big)
        if big > 1073741823 # Fixnum max
          big -= (2**32) # diminished radix wrap to negative
        end
        big
      end

      private :negative_complement

      def load_current_resource
        @current_resource = Chef::Resource::Link.new(new_resource.name)
        current_resource.target_file(new_resource.target_file)
        if file_class.symlink?(current_resource.target_file)
          current_resource.link_type(:symbolic)
          current_resource.to(
            canonicalize(file_class.readlink(current_resource.target_file))
          )
        else
          current_resource.link_type(:hard)
          if ::File.exists?(current_resource.target_file)
            if ::File.exists?(new_resource.to) &&
                file_class.stat(current_resource.target_file).ino ==
                    file_class.stat(new_resource.to).ino
              current_resource.to(canonicalize(new_resource.to))
            else
              current_resource.to("")
            end
          end
        end
        ScanAccessControl.new(new_resource, current_resource).set_all!
        current_resource
      end

      def define_resource_requirements
        requirements.assert(:delete) do |a|
          a.assertion do
            if current_resource.to
              current_resource.link_type == new_resource.link_type &&
                (current_resource.link_type == :symbolic || current_resource.to != "")
            else
              true
            end
          end
          a.failure_message Chef::Exceptions::Link, "Cannot delete #{new_resource} at #{new_resource.target_file}! Not a #{new_resource.link_type} link."
          a.whyrun("Would assume the link at #{new_resource.target_file} was previously created")
        end
      end

      def canonicalize(path)
        Chef::Platform.windows? ? path.tr("/", '\\') : path
      end

      def action_create
        # current_resource is the symlink that currently exists
        # new_resource is the symlink we need to create
        #   to - the location to link to
        #   target_file - the name of the link

        if current_resource.to != canonicalize(new_resource.to) ||
            current_resource.link_type != new_resource.link_type
          # Handle the case where the symlink already exists and is pointing at a valid to_file
          if current_resource.to
            # On Windows, to fix a symlink already pointing at a directory we must first
            # ::Dir.unlink the symlink (not the directory), while if we have a symlink
            # pointing at file we must use ::File.unlink on the symlink.
            # However if the new symlink will point to a file and the current symlink is pointing at a
            # directory we want to throw an exception and calling ::File.unlink on the directory symlink
            # will throw the correct ones.
            if Chef::Platform.windows? && ::File.directory?(new_resource.to) &&
                ::File.directory?(current_resource.target_file)
              converge_by("unlink existing windows symlink to dir at #{new_resource.target_file}") do
                ::Dir.unlink(new_resource.target_file)
              end
            else
              converge_by("unlink existing symlink to file at #{new_resource.target_file}") do
                ::File.unlink(new_resource.target_file)
              end
            end
          end
          if new_resource.link_type == :symbolic
            converge_by("create symlink at #{new_resource.target_file} to #{new_resource.to}") do
              file_class.symlink(canonicalize(new_resource.to), new_resource.target_file)
              logger.trace("#{new_resource} created #{new_resource.link_type} link from #{new_resource.target_file} -> #{new_resource.to}")
              logger.info("#{new_resource} created")
              # file_class.symlink will create the link with default access controls.
              # This means that the access controls of the file could be different
              # than those captured during the initial evaluation of current_resource.
              # We need to re-evaluate the current_resource to ensure that the desired
              # access controls are applied.
              ScanAccessControl.new(new_resource, current_resource).set_all!
            end
          elsif new_resource.link_type == :hard
            converge_by("create hard link at #{new_resource.target_file} to #{new_resource.to}") do
              file_class.link(new_resource.to, new_resource.target_file)
              logger.trace("#{new_resource} created #{new_resource.link_type} link from #{new_resource.target_file} -> #{new_resource.to}")
              logger.info("#{new_resource} created")
            end
          end
        end
        if new_resource.link_type == :symbolic
          if access_controls.requires_changes?
            converge_by(access_controls.describe_changes) do
              access_controls.set_all
            end
          end
        end
      end

      def action_delete
        if current_resource.to # Exists
          if Chef::Platform.windows? && ::File.directory?(current_resource.target_file)
            converge_by("delete link to dir at #{new_resource.target_file}") do
              ::Dir.delete(new_resource.target_file)
              logger.info("#{new_resource} deleted")
            end
          else
            converge_by("delete link to file at #{new_resource.target_file}") do
              ::File.delete(new_resource.target_file)
              logger.info("#{new_resource} deleted")
            end
          end
        end
      end

      # Implementation components *should not* follow symlinks when managing
      # access control (e.g., use lchmod instead of chmod) if the resource is a
      # symlink.
      def manage_symlink_access?
        new_resource.link_type == :symbolic
      end
    end
  end
end
