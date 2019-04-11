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
  class Provider
    class Locale < Chef::Provider
      provides :locale

      LOCALE_CONF = "/etc/locale.conf".freeze
      LOCALE_PLATFORM_FAMILIES = [ "rhel", "fedora", "amazon", "debian" ].freeze

      def load_current_resource
      end

      def define_resource_requirements
        requirements.assert(:all_actions) do |a|
          a.assertion { LOCALE_PLATFORM_FAMILIES.include?(node[:platform_family]) }
          a.failure_message(Chef::Exceptions::ProviderNotFound, "The locale resource is not supported on platform family: #{node[:platform_family]}")
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

      private

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
        r = Chef::Resource::File.new(LOCALE_CONF, run_context)
        r.content(new_content)
        r.run_action(:create)
        new_resource.updated_by_last_action(true) if r.updated?
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
