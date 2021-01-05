#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
    class YumRepository < Chef::Resource
      unified_mode true

      provides(:yum_repository) { true }

      description "Use the **yum_repository** resource to manage a Yum repository configuration file located at `/etc/yum.repos.d/repositoryid.repo` on the local machine. This configuration file specifies which repositories to reference, how to handle cached data, etc."
      introduced "12.14"
      examples <<~DOC
      **Add an internal company repository**:

      ```ruby
      yum_repository 'OurCo' do
        description 'OurCo yum repository'
        mirrorlist 'http://artifacts.ourco.org/mirrorlist?repo=ourco-8&arch=$basearch'
        gpgkey 'http://artifacts.ourco.org/pub/yum/RPM-GPG-KEY-OURCO-8'
        action :create
      end
      ```

      **Delete a repository**:

      ```ruby
      yum_repository 'CentOS-Media' do
        action :delete
      end
      ```
      DOC

      # http://linux.die.net/man/5/yum.conf as well as
      # http://dnf.readthedocs.io/en/latest/conf_ref.html
      property :reposdir, String,
        description: "The directory where the Yum repository files should be stored",
        default: "/etc/yum.repos.d/",
        introduced: "16.9"

      property :baseurl, [String, Array],
        description: "URL to the directory where the Yum repository's `repodata` directory lives. Can be an `http://`, `https://` or a `ftp://` URLs. You can specify multiple URLs in one `baseurl` statement."

      property :clean_headers, [TrueClass, FalseClass],
        description: "Specifies whether you want to purge the package data files that are downloaded from a Yum repository and held in a cache directory.",
        deprecated: true,
        default: false

      property :clean_metadata, [TrueClass, FalseClass],
        description: "Specifies whether you want to purge all of the packages downloaded from a Yum repository and held in a cache directory.",
        default: true

      property :cost, String, regex: /^\d+$/,
               description: "Relative cost of accessing this repository. Useful for weighing one repo's packages as greater/less than any other.",
               validation_message: "The cost property must be a numeric value!"

      property :description, String,
        description: "Descriptive name for the repository channel and maps to the 'name' parameter in a repository .conf.",
        default: "Yum Repository"

      property :enabled, [TrueClass, FalseClass],
        description: "Specifies whether or not Yum should use this repository.",
        default: true

      property :enablegroups, [TrueClass, FalseClass],
        description: "Specifies whether Yum will allow the use of package groups for this repository."

      property :exclude, String,
        description: "List of packages to exclude from updates or installs. This should be a space separated list. Shell globs using wildcards (eg. * and ?) are allowed."

      property :failovermethod, String,
        description: "Method to determine how to switch to a new server if the current one fails, which can either be `roundrobin` or `priority`. `roundrobin` randomly selects a URL out of the list of URLs to start with and proceeds through each of them as it encounters a failure contacting the host. `priority` starts from the first `baseurl` listed and reads through them sequentially.",
        equal_to: %w{priority roundrobin}

      property :fastestmirror_enabled, [TrueClass, FalseClass],
        description: "Specifies whether to use the fastest mirror from a repository configuration when more than one mirror is listed in that configuration."

      property :gpgcheck, [TrueClass, FalseClass],
        description: "Specifies whether or not Yum should perform a GPG signature check on the packages received from a repository.",
        default: true

      property :gpgkey, [String, Array],
        description: "URL pointing to the ASCII-armored GPG key file for the repository. This is used if Yum needs a public key to verify a package and the required key hasn't been imported into the RPM database. If this option is set, Yum will automatically import the key from the specified URL. Multiple URLs may be specified in the same manner as the baseurl option. If a GPG key is required to install a package from a repository, all keys specified for that repository will be installed.\nMultiple URLs may be specified in the same manner as the baseurl option. If a GPG key is required to install a package from a repository, all keys specified for that repository will be installed."

      property :http_caching, String, equal_to: %w{packages all none},
               description: "Determines how upstream HTTP caches are instructed to handle any HTTP downloads that Yum does. This option can take the following values:\n - `all` means all HTTP downloads should be cached\n - `packages` means only RPM package downloads should be cached, but not repository metadata downloads\n - `none` means no HTTP downloads should be cached.\n\nThe default value of `all` is recommended unless you are experiencing caching related issues."

      property :include_config, String,
        description: "An external configuration file using the format `url://to/some/location`."

      property :includepkgs, String,
        description: "Inverse of exclude property. This is a list of packages you want to use from a repository. If this option lists only one package then that is all Yum will ever see from the repository."

      property :keepalive, [TrueClass, FalseClass],
        description: "Determines whether or not HTTP/1.1 `keep-alive` should be used with this repository."

      property :make_cache, [TrueClass, FalseClass],
        description: "Determines whether package files downloaded by Yum stay in cache directories. By using cached data, you can carry out certain operations without a network connection.",
        default: true

      property :max_retries, [String, Integer],
        description: "Number of times any attempt to retrieve a file should retry before returning an error. Setting this to `0` makes Yum try forever."

      property :metadata_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/, /never/],
               description: "Time (in seconds) after which the metadata will expire. If the current metadata downloaded is less than the value specified, then Yum will not update the metadata against the repository. If you find that Yum is not downloading information on updates as often as you would like lower the value of this option. You can also change from the default of using seconds to using days, hours or minutes by appending a `d`, `h` or `m` respectively. The default is six hours to compliment yum-updates running once per hour. It is also possible to use the word `never`, meaning that the metadata will never expire. Note: When using a metalink file, the metalink must always be newer than the metadata for the repository due to the validation, so this timeout also applies to the metalink file.",
               validation_message: "The metadata_expire property must be a numeric value for time in seconds, the string 'never', or a numeric value appended with with `d`, `h`, or `m`!"

      property :metalink, String,
        description: "Specifies a URL to a metalink file for the repomd.xml, a list of mirrors for the entire repository are generated by converting the mirrors for the repomd.xml file to a baseurl."

      property :mirror_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/],
               description: "Time (in seconds) after which the mirrorlist locally cached will expire. If the current mirrorlist is less than this many seconds old then Yum will not download another copy of the mirrorlist, it has the same extra format as metadata_expire. If you find that Yum is not downloading the mirrorlists as often as you would like lower the value of this option. You can also change from the default of using seconds to using days, hours or minutes by appending a `d`, `h` or `m` respectively.",
               validation_message: "The mirror_expire property must be a numeric value for time in seconds, the string 'never', or a numeric value appended with with `d`, `h`, or `m`!"

      property :mirrorlist_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/],
               description: "Specifies the time (in seconds) after which the mirrorlist locally cached will expire. If the current mirrorlist is less than the value specified, then Yum will not download another copy of the mirrorlist. You can also change from the default of using seconds to using days, hours or minutes by appending a `d`, `h` or `m` respectively.",
               validation_message: "The mirrorlist_expire property must be a numeric value for time in seconds, the string 'never', or a numeric value appended with with `d`, `h`, or `m`!"

      property :mirrorlist, String,
        description: "URL to a file containing a list of baseurls. This can be used instead of or with the baseurl option. Substitution variables, described below, can be used with this option."

      property :mode, [String, Integer],
        description: "Permissions mode of .repo file on disk. This is useful for scenarios where secrets are in the repo file. If this value is set to `600`, normal users will not be able to use Yum search, Yum info, etc.",
        default: "0644"

      property :options, Hash,
        description: "Specifies the repository options."

      property :password, String,
        description: "Password to use with the username for basic authentication."

      property :priority, String, regex: /^(\d?[1-9]|[0-9][0-9])$/,
               description: "Assigns a priority to a repository where the priority value is between `1` and `99` inclusive. Priorities are used to enforce ordered protection of repositories. Packages from repositories with a lower priority (higher numerical value) will never be used to upgrade packages that were installed from a repository with a higher priority (lower numerical value). The repositories with the lowest numerical priority number have the highest priority.",
               validation_message: "The priority property must be a numeric value from 1-99!"

      property :proxy_password, String,
        description: "Password for this proxy."

      property :proxy_username, String,
        description: "Username to use for proxy."

      property :proxy, String,
        description: "URL to the proxy server that Yum should use."

      property :repo_gpgcheck, [TrueClass, FalseClass],
        description: "Determines whether or not Yum should perform a GPG signature check on the repodata from this repository."

      property :report_instanceid, [TrueClass, FalseClass],
        description: "Determines whether to report the instance ID when using Amazon Linux AMIs and repositories."

      property :repositoryid, String, regex: [%r{^[^/]+$}],
               description: "An optional property to set the repository name if it differs from the resource block's name.",
               validation_message: "repositoryid property cannot contain a forward slash '/'",
               name_property: true

      property :skip_if_unavailable, [TrueClass, FalseClass],
        description: "Allow yum to continue if this repository cannot be contacted for any reason."

      property :source, String,
        description: "Use a custom template source instead of the default one."

      property :sslcacert, String,
        description: "Path to the directory containing the databases of the certificate authorities Yum should use to verify SSL certificates."

      property :sslclientcert, String,
        description: "Path to the SSL client certificate Yum should use to connect to repos/remote sites."

      property :sslclientkey, String,
        description: "Path to the SSL client key Yum should use to connect to repos/remote sites."

      property :sslverify, [TrueClass, FalseClass],
        description: "Determines whether Yum will verify SSL certificates/hosts."

      property :throttle, [String, Integer],
        description: "Enable bandwidth throttling for downloads."

      property :timeout, String, regex: /^\d+$/,
               description: "Number of seconds to wait for a connection before timing out. Defaults to 30 seconds. This may be too short of a time for extremely overloaded sites.",
               validation_message: "The timeout property must be a numeric value!"

      property :username, String,
        description: "Username to use for basic authentication to a repository."

      default_action :create
      allowed_actions :create, :remove, :makecache, :add, :delete

      # provide compatibility with the yum cookbook < 3.0 properties
      alias_method :url, :baseurl
      alias_method :keyurl, :gpgkey
      alias_method :mirrorexpire, :mirror_expire
    end
  end
end
