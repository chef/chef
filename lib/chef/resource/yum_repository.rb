#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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
    class YumRepository < Chef::Resource
      resource_name :yum_repository
      provides :yum_repository

      # http://linux.die.net/man/5/yum.conf as well as
      # http://dnf.readthedocs.io/en/latest/conf_ref.html
      property :baseurl, [String, Array], regex: /.*/
      property :clean_headers, [TrueClass, FalseClass], default: false # deprecated
      property :clean_metadata, [TrueClass, FalseClass], default: true
      property :cost, String, regex: /^\d+$/
      property :description, String, regex: /.*/, default: "Yum Repository"
      property :enabled, [TrueClass, FalseClass], default: true
      property :enablegroups, [TrueClass, FalseClass]
      property :exclude, String, regex: /.*/
      property :failovermethod, String, equal_to: %w{priority roundrobin}
      property :fastestmirror_enabled, [TrueClass, FalseClass]
      property :gpgcheck, [TrueClass, FalseClass], default: true
      property :gpgkey, [String, Array], regex: /.*/
      property :http_caching, String, equal_to: %w{packages all none}
      property :include_config, String, regex: /.*/
      property :includepkgs, String, regex: /.*/
      property :keepalive, [TrueClass, FalseClass]
      property :make_cache, [TrueClass, FalseClass], default: true
      property :max_retries, [String, Integer]
      property :metadata_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/, /never/]
      property :metalink, String, regex: /.*/
      property :mirror_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/]
      property :mirrorexpire, String, regex: /.*/
      property :mirrorlist_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/]
      property :mirrorlist, String, regex: /.*/
      property :mode, default: "0644"
      property :options, Hash
      property :password, String, regex: /.*/
      property :priority, String, regex: /^(\d?[0-9]|[0-9][0-9])$/
      property :proxy_password, String, regex: /.*/
      property :proxy_username, String, regex: /.*/
      property :proxy, String, regex: /.*/
      property :repo_gpgcheck, [TrueClass, FalseClass]
      property :report_instanceid, [TrueClass, FalseClass]
      property :repositoryid, String, regex: /.*/, name_property: true
      property :skip_if_unavailable, [TrueClass, FalseClass]
      property :source, String, regex: /.*/
      property :sslcacert, String, regex: /.*/
      property :sslclientcert, String, regex: /.*/
      property :sslclientkey, String, regex: /.*/
      property :sslverify, [TrueClass, FalseClass]
      property :timeout, String, regex: /^\d+$/
      property :throttle, [String, Integer]
      property :username, String, regex: /.*/

      default_action :create
      allowed_actions :create, :remove, :makecache, :add, :delete

      # provide compatibility with the yum cookbook < 3.0 properties
      alias_method :url, :baseurl
      alias_method :keyurl, :gpgkey
    end
  end
end
