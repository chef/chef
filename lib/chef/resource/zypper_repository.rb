#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2017 Chef Software, Inc.
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

require "chef/resource"

class Chef
  class Resource
    # The zypper_repository resource allows for the creation of Zypper package repositories on SUSE Enterprise Linux and
    # openSUSE systems. This resource maintains full compatibility with the zypper_repository resource in the existing
    # zypper cookbook.
    #
    # @since 13.3
    class ZypperRepository < Chef::Resource
      resource_name :zypper_repository
      provides :zypper_repo

      property :repo_name, String, name_property: true
      property :description, String
      property :type, String, default: "NONE"
      property :enabled, [true, false], default: true
      property :autorefresh, [true, false], default: true
      property :gpgcheck, [true, false], default: true
      property :gpgkey, String
      property :baseurl, String
      property :mirrorlist, String
      property :path, String
      property :priority, Integer, default: 99
      property :keeppackages, [true, false], default: false
      property :mode, default: "0644"
      property :refresh_cache, [true, false], default: true
      property :source, String
      property :cookbook, String
      property :gpgautoimportkeys, [true, false], default: true

      default_action :create
      allowed_actions :create, :remove, :add, :refresh

      # provide compatibility with the zypper cookbook
      alias_method :key, :gpgkey
      alias_method :uri, :baseurl
    end
  end
end
