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
               description: "Sets the default system language."

      property :lc_all, String,
               description: "Sets the fallback system language."

      action :update do
        description "Update the system's locale."

        locale_file = nil

        %w{ /etc/default/locale
            /etc/sysconfig/i18n
            /etc/environment }.each do |file|
          if ::File.exist?(file)
            locale_file = file
            break
          end
        end

        if locale_file.nil?
          raise "#{node['platform']} platform not supported by the chef locale resource."
        end

        contents = ::File.read(locale_file)

        unless up_to_date?(contents, new_resource.lang, new_resource.lc_all)
          converge_by("Applying locale settings") do
            file locale_file do
              content add_or_replace(contents, new_resource.lang, new_resource.lc_all)
            end
          end
        end
      end

      def up_to_date?(contents, lang, lc_all)
        h = parse_and_get_hash(contents)
        h["LANG"] == lang && h["LC_ALL"] == lc_all
      end

      def add_or_replace(contents, lang, lc_all)
        lang_flag = true if lang
        lc_all_flag = true if lc_all
        new_contents = []
        contents.each_line do |line|
          new_contents <<  if PARSER.match? line
                             kv = parse_and_get_hash(line)
                             if kv["LANG"] && lang
                               lang_flag = false
                               if kv["LANG"] != lang
                                 set("LANG", lang)
                               else
                                 line
                               end
                             elsif kv["LC_ALL"] && lc_all
                               lc_all_flag = false
                               if kv["LC_ALL"] != lc_all
                                 set("LC_ALL", lc_all)
                               else
                                 line
                               end
                             else
                               line
                             end
                           else
                             line
                           end
        end
        new_contents << set("LANG", lang) if lang_flag
        new_contents << set("LC_ALL", lc_all) if lc_all_flag
        new_contents.join
      end

      private

      # This will parse the string and capture the data where
      # Valid "KEY = VAL" exists. Comments and whitespaces in a line are ignored
      # Key can be any word character (letter, number, underscore)
      # Separated by "="
      # Value can also contain dots and quotations
      PARSER = /^(\s*\w+\s*)=([ \t]*[\w+."']+)/i

      def parse_and_get_hash(contents)
        # For quick matching purpose, keys are converted in upper case
        contents.scan(PARSER)
                .map { |line| [line.first.strip.upcase, line.last.strip] }
                .to_h
      end

      def set(key, val)
        "\n#{key}=#{val}\n"
      end
    end
  end
end
