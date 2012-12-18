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
require 'chef/mixin/shell_out'
require 'chef/mixin/file_class'
require 'chef/resource/link'
require 'chef/provider'
require 'chef/scan_access_control'

class Chef
  class Provider
    class Link < Chef::Provider

      include Chef::Mixin::EnforceOwnershipAndPermissions
      include Chef::Mixin::ShellOut
      include Chef::Mixin::FileClass

      def negative_complement(big)
        if big > 1073741823 # Fixnum max
          big -= (2**32) # diminished radix wrap to negative
        end
        big
      end

      private :negative_complement

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::Link.new(@new_resource.name)
        @current_resource.target_file(@new_resource.target_file)
        if file_class.symlink?(@current_resource.target_file)
          @current_resource.link_type(:symbolic)
          @current_resource.to(
            canonicalize(file_class.readlink(@current_resource.target_file))
          )
        else
          @current_resource.link_type(:hard)
          if ::File.exists?(@current_resource.target_file)
            if ::File.exists?(@new_resource.to) &&
               file_class.stat(@current_resource.target_file).ino ==
               file_class.stat(@new_resource.to).ino
              @current_resource.to(canonicalize(@new_resource.to))
            else
              @current_resource.to("")
            end
          end
        end
        ScanAccessControl.new(@new_resource, @current_resource).set_all!
        @current_resource
      end

      def define_resource_requirements
        requirements.assert(:delete) do |a|
          a.assertion do
            if @current_resource.to
              @current_resource.link_type == @new_resource.link_type and
              (@current_resource.link_type == :symbolic  or @current_resource.to != '')
            else
              true
            end
          end
          a.failure_message Chef::Exceptions::Link, "Cannot delete #{@new_resource} at #{@new_resource.target_file}! Not a #{@new_resource.link_type.to_s} link."
          a.whyrun("Would assume the link at #{@new_resource.target_file} was previously created")
        end
      end

      def canonicalize(path)
        Chef::Platform.windows? ? path.gsub('/', '\\') : path
      end

      def action_create
        if @current_resource.to != canonicalize(@new_resource.to) ||
           @current_resource.link_type != @new_resource.link_type
          if @current_resource.to # nil if target_file does not exist
            converge_by("unlink existing file at #{@new_resource.target_file}") do
              ::File.unlink(@new_resource.target_file)
            end
          end
          if @new_resource.link_type == :symbolic
            converge_by("create symlink at #{@new_resource.target_file} to #{@new_resource.to}") do
              file_class.symlink(canonicalize(@new_resource.to),@new_resource.target_file)
              Chef::Log.debug("#{@new_resource} created #{@new_resource.link_type} link from #{@new_resource.to} -> #{@new_resource.target_file}")
              Chef::Log.info("#{@new_resource} created")
            end
          elsif @new_resource.link_type == :hard
            converge_by("create hard link at #{@new_resource.target_file} to #{@new_resource.to}") do
              file_class.link(@new_resource.to, @new_resource.target_file)
              Chef::Log.debug("#{@new_resource} created #{@new_resource.link_type} link from #{@new_resource.to} -> #{@new_resource.target_file}")
              Chef::Log.info("#{@new_resource} created")
            end
          end
        end
        if @new_resource.link_type == :symbolic
          if access_controls.requires_changes?
            converge_by(access_controls.describe_changes) do 
              access_controls.set_all
            end
          end
       end
      end

      def action_delete
        if @current_resource.to # Exists
          converge_by ("delete link at #{@new_resource.target_file}") do
            ::File.delete(@new_resource.target_file)
            Chef::Log.info("#{@new_resource} deleted")
          end
        end
      end
    end
  end
end
