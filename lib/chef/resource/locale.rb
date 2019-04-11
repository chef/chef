#
# Copyright:: 2011-2016, Heavy Water Software Inc.
# Copyright:: 2016-2018, Chef Software Inc.
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
# See the License for the specific slanguage governing permissions and
# limitations under the License.
#

require "chef/resource"

class Chef
  class Resource
    class Locale < Chef::Resource
      resource_name :locale

      description "Use the locale resource to set the system's locale."
      introduced "14.5"
      default_action :update
      allowed_actions :update

      LC_VARIABLES = %w{LC_ADDRESS LC_COLLATE LC_CTYPE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE LC_TIME}.freeze
      LOCALE_REGEX = /\A\S+/.freeze

      property :lang, String,
               description: "Sets the default system language.",
               regex: [LOCALE_REGEX],
               validation_message: "The provided lang is not valid. It should be a non-empty string without any leading whitespaces."

      property :lc_env, Hash,
               description: "A Hash of LC_* env variables in the form of ({ 'LC_ENV_VARIABLE' => 'VALUE' }).",
               default: lazy { {} },
               coerce: proc { |h|
                         if h.respond_to?(:keys)
                           invalid_keys = h.keys - LC_VARIABLES
                           unless invalid_keys.empty?
                             error_msg = "Key of option lc_env must be equal to one of: \"#{LC_VARIABLES.join('", "')}\"!  You passed \"#{invalid_keys.join(', ')}\"."
                             raise Chef::Exceptions::ValidationFailed, error_msg
                           end
                         end
                         unless h.values.all? { |x| x =~ LOCALE_REGEX }
                           error_msg = "Values of option lc_env should be non-empty string without any leading whitespaces."
                           raise Chef::Exceptions::ValidationFailed, error_msg
                         end
                         h
                       }

      # @deprecated Use {#lc_env} instead of this property.
      #   {#lc_env} uses Hash with specific LC var as key.
      # @raise [Chef::Deprecated]
      #
      def lc_all(arg = nil)
        unless arg.nil?
          Chef.deprecated(:locale_lc_all, "Changing LC_ALL can break Chef's parsing of command output in unobvious ways and is no longer supported.\nUse one of the more specific LC_ properties.")
        end
      end
    end
  end
end
