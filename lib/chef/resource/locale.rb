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

require_relative "../resource"
require_relative "../dist"

class Chef
  class Resource
    class Locale < Chef::Resource
      resource_name :locale

      description "Use the locale resource to set the system's locale."
      introduced "14.5"

      LC_VARIABLES = %w{LC_ADDRESS LC_COLLATE LC_CTYPE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE LC_TIME}.freeze
      LOCALE_CONF = "/etc/locale.conf".freeze
      LOCALE_REGEX = /\A\S+/.freeze
      LOCALE_PLATFORM_FAMILIES = %w{debian}.freeze

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
          Chef.deprecated(:locale_lc_all, "Changing LC_ALL can break #{Chef::Dist::PRODUCT}'s parsing of command output in unexpected ways.\n Use one of the more specific LC_ properties as needed.")
        end
      end

      action :update do
        description "Update the system's locale."
        begin
          unless up_to_date?
            converge_by "Updating System Locale" do
              generate_locales unless unavailable_locales.empty?
              update_locale
            end
          end
        end
      end

      action_class do
        # Avoid running this resource on platforms that don't use /etc/locale.conf
        #
        def define_resource_requirements
          requirements.assert(:all_actions) do |a|
            a.assertion { LOCALE_PLATFORM_FAMILIES.include?(node[:platform_family]) }
            a.failure_message(Chef::Exceptions::ProviderNotFound, "The locale resource is not supported on platform family: #{node[:platform_family]}")
          end

          requirements.assert(:all_actions) do |a|
            # RHEL/CentOS type platforms don't have locale-gen
            a.assertion { shell_out("locale-gen") }
            a.failure_message(Chef::Exceptions::ProviderNotFound, "The locale resource requires the locale-gen tool")
          end
        end

        # Generates the localisation files from templates using locale-gen.
        # @see http://manpages.ubuntu.com/manpages/cosmic/man8/locale-gen.8.html
        # @raise [Mixlib::ShellOut::ShellCommandFailed] not a supported language or locale
        #
        def generate_locales
          shell_out!("locale-gen #{unavailable_locales.join(' ')}")
        end

        # Updates system locale by appropriately writing them in /etc/locale.conf
        # @note This locale change won't affect the current run. At this time it is an exercise
        # left to the user to restart or reboot if the locale change is required at
        # later part of the client run.
        # @see https://wiki.archlinux.org/index.php/locale#Setting_the_system_locale
        #
        def update_locale
          file "Updating system locale" do
            path LOCALE_CONF
            content new_content
          end
        end

        # @return [Array<String>] Locales that user wants to set but are not available on
        #   the system. They are required to be generated.
        #
        def unavailable_locales
          @unavailable_locales ||= begin
            available = shell_out!("locale -a").stdout.split("\n")
            required = [new_resource.lang, new_resource.lc_env.values].flatten.compact.uniq
            required - available
          end
        end

        # @return [String] Contents that are required to be
        #   updated in /etc/locale.conf
        #
        def new_content
          @new_content ||= begin
            content = {}
            content = new_resource.lc_env.dup if new_resource.lc_env
            content["LANG"] = new_resource.lang if new_resource.lang
            content.sort.map { |t| t.join("=") }.join("\n") + "\n"
          end
        end

        # @return [Boolean] Whether any modification is required in /etc/locale.conf
        #
        def up_to_date?
          old_content = ::File.read(LOCALE_CONF)
          new_content == old_content
        rescue
          false # We need to create the file if it is not present
        end
      end
    end
  end
end
