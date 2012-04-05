#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
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

require 'chef/log'

class Chef

  # == Chef::FileAccessControl
  # FileAccessControl objects set the owner, group and mode of +file+ to
  # the values specified by a value object, usually a Chef::Resource.
  class FileAccessControl

    if RUBY_PLATFORM =~ /mswin|mingw|windows/
      require 'chef/file_access_control/windows'
      include FileAccessControl::Windows
    else
      require 'chef/file_access_control/unix'
      include FileAccessControl::Unix
    end

    attr_reader :current_resource
    attr_reader :resource
    attr_reader :file

    # FileAccessControl objects set the owner, group and mode of +file+ to
    # the values specified by +resource+. +file+ is completely independent
    # of any file or path attribute on +resource+, so it is possible to set
    # access control settings on a tempfile (for example).
    # === Arguments:
    # resource:   probably a Chef::Resource::File object (or subclass), but
    #             this is not required. Must respond to +owner+, +group+,
    #             and +mode+
    # file:       The file whose access control settings you wish to modify,
    #             given as a String.
    #
    # TODO requiring current_resource will break cookbook_file template_file
    def initialize(current_resource, new_resource)
      @current_resource, @resource = current_resource, new_resource
      @file = @current_resource.path
      @modified = false
    end

    def modified?
      @modified
    end

    private

    def modified
      @modified = true
    end

    def log_string
      @resource || @file
    end

  end
end
