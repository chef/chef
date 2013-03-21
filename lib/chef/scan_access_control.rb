#
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
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
  class ScanAccessControl
    if Chef::Platform.windows?
      require 'chef/scan_access_control/windows.rb'
      include ScanAccessControl::Windows
    else
      require 'chef/scan_access_control/unix.rb'
      include ScanAccessControl::Unix
    end

    attr_reader :new_resource
    attr_reader :current_resource

    def initialize(new_resource, current_resource)
      @new_resource, @current_resource = new_resource, current_resource
    end

    # must be overrode by children unix.rb and windows.rb
    def set_all!
    end

  end
end
