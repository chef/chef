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

        if ::File.exist?("/etc/default/locale")
          locale_file = "/etc/default/locale"
        elsif ::File.exist?("/etc/sysconfig/i18n")
          locale_file = "/etc/sysconfig/i18n"
        elsif ::File.exist?("/etc/environment")
          locale_file = "/etc/environment"
        else
          raise "#{node["platform"]} platform not supported by the chef locale resource."
        end

        contents = IO.readlines(locale_file)
        env_val = contents.map { |t| t.split("=") if t.include?("=") }.compact.to_h

        unless up_to_date?(env_val)
          execute "Generate locales" do
            command "locale-gen #{new_resource.lang}"
            only_if { locale_file == "/etc/default/locale" }
          end

          file locale_file do
            content replace(env_val)
          end
        end
      end

      action_class do
        def up_to_date?(hash)
          hash["LANG"] && new_resource.lang == hash["LANG"].gsub(/\n|"/, "") &&
            hash["LC_ALL"] && new_resource.lc_all == hash["LC_ALL"].gsub(/\n|"/, "")
        end

        def replace(hash)
          hash["LANG"] = "\"#{new_resource.lang}\""
          hash["LC_ALL"] = "\"#{new_resource.lc_all}\""
          hash.to_a.map { |t| t.join("=") }.join("\n")
        end
      end
    end
  end
end
