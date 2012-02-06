#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

class Chef
  # == ScanAccessControl
  # Reads Access Control Settings on a file and writes them out to a resource
  # (should be the current_resource), attempting to match the style used by the
  # new resource, that is, if users are specified with usernames in
  # new_resource, then the uids from stat will be looked up and usernames will
  # be added to current_resource.
  #
  # === Why?
  # FileAccessControl objects may operate on a temporary file, in which case we
  # won't know if the access control settings changed (ex: rendering a template
  # with both a change in content and ownership). For auditing purposes, we
  # need to record the current state of a file system entity.
  #--
  # Not yet sure if this is the optimal way to solve the problem. But it's
  # progress towards the end goal.
  #
  # TODO: figure out if all this works with OS X's negative uids
  # TODO: windows
  class ScanAccessControl

    attr_reader :new_resource
    attr_reader :current_resource

    def initialize(new_resource, current_resource)
      @new_resource, @current_resource = new_resource, current_resource
    end

    # Modifies @current_resource, setting the current access control state.
    def set_all!
      if File.exist?(new_resource.path)
        set_owner
        set_group
        set_mode
      else
        # leave the values as nil.
      end
    end

    # Set the owner attribute of +current_resource+ to whatever the current
    # state is. Attempts to match the format given in new_resource: if the
    # new_resource specifies the owner as a string, the username for the uid
    # will be looked up and owner will be set to the username, and vice versa.
    def set_owner
      @current_resource.owner(current_owner)
    end

    def current_owner
      case new_resource.owner
      when nil
        nil
      when String
        lookup_uid
      when Integer
        stat.uid
      else
        Chef::Log.error("The `owner` parameter of the #@new_resource resource is set to an invalid value (#{new_resource.owner.inspect})")
        raise ArgumentError, "cannot resolve #{new_resource.owner.inspect} to uid, owner must be a string or integer"
      end
    end

    def lookup_uid
      Etc.getpwuid(stat.uid).name
    rescue ArgumentError
      stat.uid
    end

    # Set the group attribute of +current_resource+ to whatever the current state is.
    def set_group
      @current_resource.group(current_group)
    end

    def current_group
      case new_resource.group
      when nil
        nil
      when String
        lookup_gid
      when Integer
        stat.gid
      else
        Chef::Log.error("The `group` parameter of the #@new_resource resource is set to an invalid value (#{new_resource.owner.inspect})")
        raise ArgumentError, "cannot resolve #{new_resource.group.inspect} to gid, group must be a string or integer"
      end
    end

    def lookup_gid
      Etc.getgrgid(stat.gid).name
    rescue ArgumentError
      stat.gid
    end

    def set_mode
      @current_resource.mode(current_mode)
    end

    def current_mode
      case new_resource.mode
      when nil
        nil
      when String
        (stat.mode & 007777).to_s(8)
      when Integer
        stat.mode & 007777
      else
        Chef::Log.error("The `mode` parameter of the #@new_resource resource is set to an invalid value (#{new_resource.mode.inspect})")
        raise ArgumentError, "Invalid value #{new_resource.mode.inspect} for `mode` on resource #@new_resource"
      end
    end

    def stat
      @stat ||= ::File.stat(@new_resource.path)
    end
  end
end
