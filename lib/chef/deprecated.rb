#--
# Copyright:: Copyright 2016-2017, Chef Software Inc.
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

require "chef/mixin/convert_to_class_name"

# Structured deprecations have a unique URL associated with them, which must exist before the deprecation is merged.
class Chef
  class Deprecated

    class << self
      include Chef::Mixin::ConvertToClassName

      def create(type, message = nil, location = nil)
        Chef::Deprecated.const_get(convert_to_class_name(type.to_s)).send(:new, message, location)
      end
    end

    class Base
      BASE_URL = "https://docs.chef.io/deprecations_"

      attr_accessor :message, :location

      def initialize(msg = nil, location = nil)
        @message = msg if msg
        @location = location if location
      end

      def link
        "Please see #{url} for further details and information on how to correct this problem."
      end

      def url
        "#{BASE_URL}#{target}"
      end

      # We know that the only time this gets called is by Chef::Log.deprecation,
      # so special case
      def <<(location)
        @location = location
      end

      def inspect
        "#{message} (CHEF-#{id})#{location}.\n#{link}"
      end

      def id
        raise NotImplementedError, "subclasses of Chef::Deprecated::Base should define #id with a unique number"
      end

      def target
        raise NotImplementedError, "subclasses of Chef::Deprecated::Base should define #target"
      end
    end

    class InternalApi < Base
      def id
        0
      end

      def target
        "internal_api.html"
      end
    end

    class JsonAutoInflate < Base
      def id
        1
      end

      def target
        "json_auto_inflate.html"
      end
    end

    class ExitCode < Base
      def id
        2
      end

      def target
        "exit_code.html"
      end
    end

    # id 3 has been deleted

    class Attributes < Base
      def id
        4
      end

      def target
        "attributes.html"
      end
    end

    class CustomResource < Base
      def id
        5
      end

      def target
        "custom_resource_cleanups.html"
      end
    end

    class EasyInstall < Base
      def id
        6
      end

      def target
        "easy_install.html"
      end
    end

    class VerifyFile < Base
      def id
        7
      end

      def target
        "verify_file.html"
      end
    end

    class SupportsProperty < Base
      def id
        8
      end

      def target
        "supports_property.html"
      end
    end

    class ChefRest < Base
      def id
        9
      end

      def target
        "chef_rest.html"
      end
    end

    class DnfPackageAllowDowngrade < Base
      def id
        10
      end

      def target
        "dnf_package_allow_downgrade.html"
      end
    end

    class PropertyNameCollision < Base
      def id
        11
      end

      def target
        "property_name_collision.html"
      end
    end

    class LaunchdHashProperty < Base
      def id
        12
      end

      def target
        "launchd_hash_property.html"
      end
    end

    class ChefPlatformMethods < Base
      def id
        13
      end

      def target
        "chef_platform_methods.html"
      end
    end

    class RunCommand < Base
      def id
        14
      end

      def target
        "run_command.html"
      end
    end

    class PackageMisc < Base
      def id
        15
      end

      def target
        "package_misc.html"
      end
    end

    class MultiresourceMatch < Base
      def id
        16
      end

      def target
        "multiresource_match.html"
      end
    end

    class UseInlineResources < Base
      def id
        17
      end

      def target
        "use_inline_resources.html"
      end
    end

    class LocalListen < Base
      def id
        18
      end

      def target
        "local_listen.html"
      end
    end

    # id 3694 was deleted

    class Generic < Base
      def url
        "https://docs.chef.io/chef_deprecations_client.html"
      end

      def inspect
        "#{message}\nThis is a generic error message and should be updated to have a proper deprecation class. #{location}\nPlease see #{url} for an overview of Chef deprecations."
      end
    end

  end
end
