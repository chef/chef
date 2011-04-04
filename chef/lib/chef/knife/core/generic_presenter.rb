#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/knife/core/text_formatter'

class Chef
  class Knife
    module Core
      class GenericPresenter

        attr_reader :ui
        attr_reader :config

        def initialize(ui, config)
          @ui, @config = ui, config
        end

        def format(data)
          case config[:format]
          when "summary", nil
            summarize(data)
          when "text"
            text_format(data)
          when "json"
            Chef::JSONCompat.to_json_pretty(data)
          when "yaml"
            require 'yaml'
            YAML::dump(data)
          when "pp"
            # If you were looking for some attribute and there is only one match
            # just dump the attribute value
            if data.length == 1 and config[:attribute]
              data.values[0]
            else
              out = StringIO.new
              PP.pp(data, out)
              out.string
            end
          else
            raise ArgumentError, "Unknown output format #{config[:format]}"
          end
        end

        # Summarize the data. Defaults to text format output,
        # which may not be very summary-like
        def summarize(data)
          text_format(data)
        end

        def text_format(data)
          TextFormatter.new(data, ui).formatted_data
        end

        def format_list_for_display(list)
          config[:with_uri] ? list : list.keys.sort { |a,b| a <=> b }
        end

        def format_for_display(data)
          if config[:attribute]
            config[:attribute].split(".").each do |attr|
              if data.respond_to?(:[])
                data = data[attr]
              elsif data.nil?
                nil # don't get no method error on nil
              else data.respond_to?(attr.to_sym)
                data = data.send(attr.to_sym)
              end
            end
            { config[:attribute] => data.respond_to?(:to_hash) ? data.to_hash : data }
          elsif config[:run_list]
            data = data.run_list.run_list
            { "run_list" => data }
          elsif config[:environment]
            if data.respond_to?(:chef_environment)
              {"chef_environment" => data.chef_environment}
            else
              # this is a place holder for now. Feel free to modify (i.e. add other cases). [nuo]
              data
            end
          elsif config[:id_only]
            data.respond_to?(:name) ? data.name : data["id"]
          else
            data
          end
        end

        def format_cookbook_list_for_display(item)
          if config[:with_uri]
            item
          else
            versions_by_cookbook = item.inject({}) do |collected, ( cookbook, versions )|
              collected[cookbook] = versions["versions"].map {|v| v['version']}
              collected
            end
            key_length = versions_by_cookbook.keys.map {|name| name.size }.max + 2
            versions_by_cookbook.sort.map do |cookbook, versions|
              "#{cookbook.ljust(key_length)} #{versions.join(',')}"
            end
          end
        end

      end
    end
  end
end
