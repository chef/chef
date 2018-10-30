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

      property :lang, String,
               default: "en_US.utf8",
               description: "Sets the default system language."

      property :lc_all, String,
               default: "en_US.utf8",
               description: "Sets the fallback system language."

      action :update do
        description "Update the system's locale."

        if node["init_package"] == "systemd"
          # on systemd settings LC_ALL is (correctly) reserved only for testing and cannot be set globally
          execute "localectl set-locale LANG=#{new_resource.lang}" do
            # RHEL uses /etc/locale.conf
            not_if { up_to_date?("/etc/locale.conf", new_resource.lang) } if ::File.exist?("/etc/locale.conf")
            # Ubuntu 16.04 still uses /etc/default/locale
            not_if { up_to_date?("/etc/default/locale", new_resource.lang) } if ::File.exist?("/etc/default/locale")
          end
        elsif ::File.exist?("/etc/sysconfig/i18n")
          locale_file_path = "/etc/sysconfig/i18n"

          updated = up_to_date?(locale_file_path, new_resource.lang, new_resource.lc_all)

          file locale_file_path do
            content lazy {
              locale = IO.read(locale_file_path)
              variables = Hash[locale.lines.map { |line| line.strip.split("=") }]
              variables["LANG"] = new_resource.lang
              variables["LC_ALL"] =
                variables.map { |pairs| pairs.join("=") }.join("\n") + "\n"
            }
            not_if { updated }
          end

          execute "reload root's lang profile script" do
            command "source /etc/sysconfig/i18n; source /etc/profile.d/lang.sh"
            not_if { updated }
          end
        elsif ::File.exist?("/usr/sbin/update-locale")
          execute "Generate locales" do
            command "locale-gen"
            not_if { up_to_date?("/etc/default/locale", new_resource.lang, new_resource.lc_all) }
          end

          execute "Update locale" do
            command "update-locale LANG=#{new_resource.lang} LC_ALL=#{new_resource.lc_all}"
            not_if { up_to_date?("/etc/default/locale", new_resource.lang, new_resource.lc_all) }
          end
        else
          raise "#{node["platform"]} platform not supported by the chef locale resource."
        end
      end

      action_class do
        def up_to_date?(file_path, lang, lc_all = nil)
          locale = IO.read(file_path)
          locale.include?("LANG=#{lang}") &&
            (node["init_package"] == "systemd" || lc_all.nil? || locale.include?("LC_ALL=#{lc_all}"))
        rescue
          false
        end
      end
    end
  end
end
