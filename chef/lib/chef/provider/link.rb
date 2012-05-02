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
require 'chef/resource/link'
require 'chef/provider'

class Chef
  class Provider
    class Link < Chef::Provider
      include Chef::Mixin::ShellOut

      def file_class
        @host_os_file ||= if Chef::Platform.windows?
          require 'chef/win32/file'
          Chef::Win32::File
        else
          ::File
        end
      end

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
        @current_resource.link_type(@new_resource.link_type)
        if @new_resource.link_type == :symbolic
          if ::File.exists?(@current_resource.target_file) && file_class.symlink?(@current_resource.target_file)
            @current_resource.to(
              ::File.expand_path(file_class.readlink(@current_resource.target_file))
            )
            cstats = ::File.lstat(@current_resource.target_file)
            @current_resource.owner(cstats.uid)
            @current_resource.group(cstats.gid)
          else
            @current_resource.to("")
          end
        elsif @new_resource.link_type == :hard
          if ::File.exists?(@current_resource.target_file) && ::File.exists?(@new_resource.to)
            if ::File.stat(@current_resource.target_file).ino == ::File.stat(@new_resource.to).ino
              @current_resource.to(@new_resource.to)
            else
              @current_resource.to("")
            end
          else
            @current_resource.to("")
          end
        end
        @current_resource
      end

      def define_resource_requirements
        requirements.assert(:delete) do |a|
          a.assertion do 
            puts "Link Type: #{@new_resource.link_type} symlink? #{file_class.symlink?(@new_resource.target_file)}"
            if @new_resource.link_type == :symbolic && !file_class.symlink?(@new_resource.target_file)
              ::File.exists?(@new_resource.target_file)
            else
              true
            end
          end
          a.failure_message(Chef::Exceptions::Link, "Cannot delete #{@new_resource} at #{@new_resource.target_file}! Not a symbolic link")
          a.whyrun("Would assume the file #{@new_resource.target_file} was created")
        end
        requirements.assert(:delete) do |a|
          a.assertion do 
            if @new_resource.link_type == :hard 
              if ::File.exists?(@new_resource.target_file) 
                 ::File.exists?(@new_resource.to) && file_class.stat(@current_resource.target_file).ino == file_class.stat(@new_resource.to).ino
              else
                 true
              end
            else 
              true
            end
          end
          a.failure_message(Chef::Exceptions::Link, "Cannot delete #{@new_resource} at #{@new_resource.target_file}! Not a hard link")
          a.whyrun("Would assume the file #{@new_resource.to} was created")
         end
      end

      def action_create
        if @current_resource.to != ::File.expand_path(@new_resource.to, @new_resource.target_file)
          if @new_resource.link_type == :symbolic
            unless (file_class.symlink?(@new_resource.target_file) && file_class.readlink(@new_resource.target_file) == @new_resource.to)
              if file_class.symlink?(@new_resource.target_file) || ::File.exist?(@new_resource.target_file)
                #TODO convergeby
                converge_by("Would unlink #{@new_resource.target_file}") do
                  ::File.unlink(@new_resource.target_file)
                end
              end
              converge_by("Would create symbolic link from #{@new_resource.to} -> #{@new_resource.target_file} ") do
                file_class.symlink(@new_resource.to,@new_resource.target_file)
                Chef::Log.debug("#{@new_resource} created #{@new_resource.link_type} link from #{@new_resource.to} -> #{@new_resource.target_file}")
                Chef::Log.info("#{@new_resource} created")
              end
            end
          elsif @new_resource.link_type == :hard
            #TODO convergeby
            converge_by("Would create #{@new_resource.link_type} link from #{@new_resource.to} -> #{@new_resource.target_file}") do
              file_class.link(@new_resource.to, @new_resource.target_file)
              Chef::Log.debug("#{@new_resource} created #{@new_resource.link_type} link from #{@new_resource.to} -> #{@new_resource.target_file}")
              Chef::Log.info("#{@new_resource} created")
            end
          end
          #@new_resource.updated_by_last_action(true)
        end
        if @new_resource.link_type == :symbolic
          enforce_ownership_and_permissions
          #set_all_access_controls
        end
      end

      def action_delete
        if @new_resource.link_type == :symbolic
          if file_class.symlink?(@new_resource.target_file)
            #TODO convergeby
            converge_by("Would delete #{@new_resource} for #{@new_resource.link_type}") do
              ::File.delete(@new_resource.target_file)
              Chef::Log.info("#{@new_resource} deleted")
            end
            #TODO assertion
          end
        elsif @new_resource.link_type == :hard
          #TODO assertion
          if ::File.exists?(@new_resource.target_file)
             converge_by("Would delete #{@new_resource} for #{@new_resource.link_type}") do
               ::File.delete(@new_resource.target_file)
               Chef::Log.info("#{@new_resource} deleted")
             end
          end
        end
      end

    # private
    # def hardlink?(target, to)
    #   s = file_class()
    #   if file_class.respond_to?(:hardlink?)
    #     file_class.hardlink?(target)
    #   else
    #     ::File.stat(target).ino == ::File.stat(to).ino
    #   end
    # end
    end
  end
end
