#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: 2016-2017, Chef Software, Inc.
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

require_relative "../resource"

class Chef
  class Resource
    class AptRepository < Chef::Resource
      resource_name :apt_repository
      provides(:apt_repository) { true }

      description "Use the apt_repository resource to specify additional APT repositories. Adding a new repository will update the APT package cache immediately."
      introduced "12.9"

      examples <<~DOC
        Add repository with basic settings
         ```ruby
        apt_repository 'nginx' do
          uri        'http://nginx.org/packages/ubuntu/'
          components ['nginx']
        end
        ```
         Enable Ubuntu multiverse repositories
         ```ruby
        apt_repository 'security-ubuntu-multiverse' do
          uri          'http://security.ubuntu.com/ubuntu'
          distribution 'trusty-security'
          components   ['multiverse']
          deb_src      true
        end
        ```
         Add the Nginx PPA, autodetect the key and repository url
         ```ruby
        apt_repository 'nginx-php' do
          uri          'ppa:nginx/stable'
        end
        ```
         Add the JuJu PPA, grab the key from the keyserver, and add source repo
         ```ruby
        apt_repository 'juju' do
          uri 'http://ppa.launchpad.net/juju/stable/ubuntu'
          components ['main']
          distribution 'trusty'
          key 'C8068B11'
          keyserver 'keyserver.ubuntu.com'
          action :add
          deb_src true
        end
        ```
         Add repository that requires multiple keys to authenticate packages
         ```ruby
        apt_repository 'rundeck' do
          uri 'https://dl.bintray.com/rundeck/rundeck-deb'
          distribution '/'
          key ['379CE192D401AB61', 'http://rundeck.org/keys/BUILD-GPG-KEY-Rundeck.org.key']
          keyserver 'keyserver.ubuntu.com'
          action :add
        end
        ```
         Add the Cloudera Repo of CDH4 packages for Ubuntu 12.04 on AMD64
         ```ruby
        apt_repository 'cloudera' do
          uri          'http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh'
          arch         'amd64'
          distribution 'precise-cdh4'
          components   ['contrib']
          key          'http://archive.cloudera.com/debian/archive.key'
        end
        ```
         Remove a repository from the list
         ```ruby
        apt_repository 'zenoss' do
          action :remove
        end
        ```
      DOC

      # There's a pile of [ String, nil, FalseClass ] types in these properties.
      # This goes back to Chef 12 where String didn't default to nil and we had to do
      # it ourself, which required allowing that type as well. We've cleaned up the
      # defaults, but since we allowed users to pass nil here we need to continue
      # to allow that so don't refactor this however tempting it is
      property :repo_name, String,
        regex: [%r{^[^/]+$}],
        description: "An optional property to set the repository name if it differs from the resource block's name. The value of this setting must not contain spaces.",
        validation_message: "repo_name property cannot contain a forward slash '/'",
        introduced: "14.1", name_property: true

      property :uri, String,
        description: "The base of the Debian distribution."

      property :distribution, [ String, nil, FalseClass ],
        description: "Usually a distribution's codename, such as trusty, xenial or bionic. Default value: the codename of the node's distro.",
        default: lazy { node["lsb"]["codename"] }, default_description: "The LSB codename of the host such as 'bionic'."

      property :components, Array,
        description: "Package groupings, such as 'main' and 'stable'.",
        default: lazy { [] }

      property :arch, [String, nil, FalseClass],
        description: "Constrain packages to a particular CPU architecture such as 'i386' or 'amd64'."

      property :trusted, [TrueClass, FalseClass],
        description: "Determines whether you should treat all packages from this repository as authenticated regardless of signature.",
        default: false

      property :deb_src, [TrueClass, FalseClass],
        description: "Determines whether or not to add the repository as a source repo as well.",
        default: false

      property :keyserver, [String, nil, FalseClass],
        description: "The GPG keyserver where the key for the repo should be retrieved.",
        default: "keyserver.ubuntu.com"

      property :key, [String, Array, nil, FalseClass],
        description: "If a keyserver is provided, this is assumed to be the fingerprint; otherwise it can be either the URI of GPG key for the repo, or a cookbook_file.",
        default: lazy { [] }, coerce: proc { |x| x ? Array(x) : x }

      property :key_proxy, [String, nil, FalseClass],
        description: "If set, a specified proxy is passed to GPG via http-proxy=."

      property :cookbook, [String, nil, FalseClass],
        description: "If key should be a cookbook_file, specify a cookbook where the key is located for files/default. Default value is nil, so it will use the cookbook where the resource is used.",
        desired_state: false

      property :cache_rebuild, [TrueClass, FalseClass],
        description: "Determines whether to rebuild the APT package cache.",
        default: true, desired_state: false

      default_action :add
      allowed_actions :add, :remove
    end
  end
end
