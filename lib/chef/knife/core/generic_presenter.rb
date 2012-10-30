#--
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

      #==Chef::Knife::Core::GenericPresenter
      # The base presenter class for displaying structured data in knife commands.
      # This is not an abstract base class, and it is suitable for displaying
      # most kinds of objects that knife needs to display.
      class GenericPresenter

        attr_reader :ui
        attr_reader :config

        # Instaniates a new GenericPresenter. This is generally handled by the
        # Chef::Knife::UI object, though you need to match the signature of this
        # method if you intend to use your own presenter instead.
        def initialize(ui, config)
          @ui, @config = ui, config
        end

        # Is the selected output format a data interchange format?
        # Returns true if the selected output format is json or yaml, false
        # otherwise. Knife search uses this to adjust its data output so as not
        # to produce invalid JSON output.
        def interchange?
          case parse_format_option
          when :json, :yaml
            true
          else
            false
          end
        end

        # Returns a String representation of +data+ that is suitable for output
        # to a terminal or perhaps for data interchange with another program.
        # The representation of the +data+ depends on the value of the
        # `config[:format]` setting.
        def format(data)
          case parse_format_option
          when :summary
            summarize(data)
          when :text
            text_format(data)
          when :json
            Chef::JSONCompat.to_json_pretty(data)
          when :yaml
            require 'yaml'
            YAML::dump(data)
          when :pp
            require 'stringio'
            # If you were looking for some attribute and there is only one match
            # just dump the attribute value
            if config[:attribute] and data.length == 1
              data.values[0]
            else
              out = StringIO.new
              PP.pp(data, out)
              out.string
            end
          end
        end

        # Converts the user-supplied value of `config[:format]` to a Symbol
        # representing the desired output format.
        # ===Returns
        # returns one of :summary, :text, :json, :yaml, or :pp
        # ===Raises
        # Raises an ArgumentError if the desired output format could not be
        # determined from the value of `config[:format]`
        def parse_format_option
          case config[:format]
          when "summary", /^s/, nil
            :summary
          when "text", /^t/
            :text
          when "json", /^j/
            :json
          when "yaml", /^y/
            :yaml
          when "pp", /^p/
            :pp
          else
            raise ArgumentError, "Unknown output format #{config[:format]}"
          end
        end

        # Summarize the data. Defaults to text format output,
        # which may not be very summary-like
        def summarize(data)
          text_format(data)
        end

        # Converts the +data+ to a String in the text format. Uses
        # Chef::Knife::Core::TextFormatter
        def text_format(data)
          TextFormatter.new(data, ui).formatted_data
        end

        def format_list_for_display(list)
          config[:with_uri] ? list : list.keys.sort { |a,b| a <=> b }
        end

        def format_for_display(data)
          if formatting_subset_of_data?
            format_data_subset_for_display(data)
          elsif config[:id_only]
            name_or_id_for(data)
          elsif config[:environment] && data.respond_to?(:chef_environment)
            {"chef_environment" => data.chef_environment}
          else
            data
          end
        end

        def format_data_subset_for_display(data)
          subset = if config[:attribute]
            result = {}
            Array(config[:attribute]).each do |nested_value_spec|
              nested_value = extract_nested_value(data, nested_value_spec)
              result[nested_value_spec] = nested_value
            end
            result
          elsif config[:run_list]
            run_list = data.run_list.run_list
            { "run_list" => run_list }
          else
            raise ArgumentError, "format_data_subset_for_display requires attribute, run_list, or id_only config option to be set"
          end
          {name_or_id_for(data) => subset }
        end

        def name_or_id_for(data)
          data.respond_to?(:name) ? data.name : data["id"]
        end

        def formatting_subset_of_data?
          config[:attribute] || config[:run_list]
        end


        def extract_nested_value(data, nested_value_spec)
          nested_value_spec.split(".").each do |attr|
            if data.nil?
              nil # don't get no method error on nil
            elsif data.respond_to?(attr.to_sym)
              data = data.send(attr.to_sym)
            elsif data.respond_to?(:[])
              data = data[attr]
            else
              data = begin
                data.send(attr.to_sym)
              rescue NoMethodError
                nil
              end
            end
          end
          ( !data.kind_of?(Array) && data.respond_to?(:to_hash) ) ? data.to_hash : data
        end

        def format_cookbook_list_for_display(item)
          if config[:with_uri]
            item.inject({}) do |collected, (cookbook, versions)|
              collected[cookbook] = Hash.new
              versions['versions'].each do |ver|
                collected[cookbook][ver['version']] = ver['url']
              end
              collected
            end
          else
            versions_by_cookbook = item.inject({}) do |collected, ( cookbook, versions )|
              collected[cookbook] = versions["versions"].map {|v| v['version']}
              collected
            end
            key_length = versions_by_cookbook.empty? ? 0 : versions_by_cookbook.keys.map {|name| name.size }.max + 2
            versions_by_cookbook.sort.map do |cookbook, versions|
              "#{cookbook.ljust(key_length)} #{versions.join('  ')}"
            end
          end
        end

      end
    end
  end
end
