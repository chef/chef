#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016-2017 Chef Software, Inc.
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
    # Use the yum_repository resource to manage a Yum repository configuration file located at /etc/yum.repos.d/repositoryid.repo
    # on the local machine. This configuration file specifies which repositories to reference, how to handle cached data, etc.
    #
    # @since 12.14
    class YumRepository < Chef::Resource
      resource_name :yum_repository
      provides :yum_repository

      # http://linux.die.net/man/5/yum.conf as well as
      # http://dnf.readthedocs.io/en/latest/conf_ref.html
      property :baseurl, [String, Array]
      property :clean_headers, [TrueClass, FalseClass], default: false # deprecated
      property :clean_metadata, [TrueClass, FalseClass], default: true
      property :cost, String, regex: /^\d+$/
      property :description, String, default: "Yum Repository"
      property :enabled, [TrueClass, FalseClass], default: true
      property :enablegroups, [TrueClass, FalseClass]
      property :exclude, String
      property :failovermethod, String, equal_to: %w{priority roundrobin}
      property :fastestmirror_enabled, [TrueClass, FalseClass]
      property :gpgcheck, [TrueClass, FalseClass], default: true
      property :gpgkey, [String, Array]
      property :http_caching, String, equal_to: %w{packages all none}
      property :include_config, String
      property :includepkgs, String
      property :keepalive, [TrueClass, FalseClass]
      property :make_cache, [TrueClass, FalseClass], default: true
      property :max_retries, [String, Integer]
      property :metadata_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/, /never/]
      property :metalink, String
      property :mirror_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/]
      property :mirrorexpire, String
      property :mirrorlist_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/]
      property :mirrorlist, String
      property :mode, default: "0644"
      property :options, Hash
      property :password, String
      property :priority, String, regex: /^(\d?[1-9]|[0-9][0-9])$/
      property :proxy_password, String
      property :proxy_username, String
      property :proxy, String
      property :repo_gpgcheck, [TrueClass, FalseClass]
      property :report_instanceid, [TrueClass, FalseClass]
      property :repositoryid, String, name_property: true
      property :skip_if_unavailable, [TrueClass, FalseClass]
      property :source, String
      property :sslcacert, String
      property :sslclientcert, String
      property :sslclientkey, String
      property :sslverify, [TrueClass, FalseClass]
      property :throttle, [String, Integer]
      property :timeout, String, regex: /^\d+$/
      property :username, String

      default_action :create
      allowed_actions :create, :remove, :makecache, :add, :delete

      # provide compatibility with the yum cookbook < 3.0 properties
      alias_method :url, :baseurl
      alias_method :keyurl, :gpgkey
    end
  end
end
