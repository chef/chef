#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  module Mixin
    # A few platform-specific providers (e.g. AIX's `service`, `cron`, and
    # `bff_package`/`package` providers) already work over Target Mode via
    # plain `shell_out!`, with no OS-native API limitations to work around.
    # Because that support ships in OSS Chef, it needs an explicit gate to
    # remain an enterprise ("premium") capability when driven remotely over
    # Target Mode: install and enable the matching `agentless_<platform>_extensions`
    # gem (see chef_premium_extensions) to unlock it.
    #
    # This gate never affects local-mode (non-Target-Mode) execution -- it
    # only fires when `Chef::Config.target_mode?` is true and no matching
    # premium plugin has been loaded.
    module TargetModePremiumGate
      # Raise a clear, actionable error unless the premium plugin gem for
      # +platform+ has been loaded via chef_premium_extensions.
      #
      # @param platform [Symbol, String] platform identifier, e.g. :aix
      # @raise [Chef::Exceptions::PremiumFeatureRequired] when running in
      #   Target Mode without the matching premium plugin loaded
      def assert_premium_target_mode!(platform)
        return unless Chef::Config.target_mode?
        return if premium_target_mode_loaded?(platform)

        gem_name = "agentless_#{platform}_extensions"
        raise Chef::Exceptions::PremiumFeatureRequired,
          "#{self.class} requires the '#{gem_name}' premium Target Mode plugin to manage " \
          "#{platform} resources remotely over Target Mode. Install the gem, set " \
          "CHEF_PREMIUM_EXTENSIONS_ENABLED=true and CHEF_TARGET_MODE_PLATFORM=#{platform}, " \
          "and ensure it is licensed. See chef_premium_extensions for details."
      end

      # @return [Boolean] true if the premium plugin gem for +platform+ has
      #   been required and defines its top-level marker module.
      def premium_target_mode_loaded?(platform)
        const_name = "Agentless#{platform.to_s.capitalize}Extensions"
        Object.const_defined?(const_name)
      end
    end
  end
end
