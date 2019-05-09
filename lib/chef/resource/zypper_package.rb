#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright 2009-2016, Joe Williams
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

require_relative "package"

class Chef
  class Resource

    class ZypperPackage < Chef::Resource::Package
      resource_name :zypper_package
      provides :package, platform_family: "suse"

      description "Use the zypper_package resource to install, upgrade, and remove packages with Zypper for the SUSE Enterprise and OpenSUSE platforms."

      property :gpg_check, [ TrueClass, FalseClass ],
               description: "Verify the package's GPG signature. Can also be controlled site-wide using the ``zypper_check_gpg`` config option.",
               default: lazy { Chef::Config[:zypper_check_gpg] }, default_description: "true"

      property :allow_downgrade, [ TrueClass, FalseClass ],
               description: "Allow downgrading a package to satisfy requested version requirements.",
               default: true,
               desired_state: false,
               introduced: "13.6"

      property :global_options, [ String, Array ],
               description: "One (or more) additional command options that are passed to the command. For example, common zypper directives, such as '--no-recommends'. See the zypper man page at https://en.opensuse.org/SDB:Zypper_manual_(plain) for the full list.",
               coerce: proc { |x| x.is_a?(String) ? x.shellsplit : x },
               introduced: "14.6"
    end
  end
end
