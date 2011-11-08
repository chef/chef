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

class Chef
  class Knife
    module Core
      class TextFormatter

        attr_reader :data
        attr_reader :ui

        def initialize(data, ui)
          @ui = ui
          @data = if data.respond_to?(:display_hash)
            data.display_hash
          elsif data.kind_of?(Array)
            data
          elsif data.respond_to?(:to_hash)
            data.to_hash
          else
            data
          end
        end

        def formatted_data
          @formatted_data ||= text_format(data)
        end

        def text_format(data, indent=0)
          buffer = ''

          if data.respond_to?(:keys)
            justify_width = data.keys.map {|k| k.to_s.size }.max.to_i + 2
            data.sort.each do |key, value|
              justified_key = ui.color("#{key}:".ljust(justify_width), :cyan)
              if should_enumerate?(value)
                buffer << indent_line(justified_key, indent)
                buffer << text_format(value, indent + 1)
              else
                buffer << indent_key_value(justified_key, value, justify_width, indent)
              end
            end
          elsif data.kind_of?(Array)
            data.each do |item|
              if should_enumerate?(data)
                buffer << text_format(item, indent + 1)
              else
                buffer << indent_line(item, indent)
              end
            end
          else
            buffer << indent_line(stringify_value(data), indent)
          end
          buffer
        end

        # Ruby 1.8 Strings include enumberable, which is not what we want. So
        # we have this heuristic to detect hashes and arrays instead.
        def should_enumerate?(value)
          ((value.respond_to?(:keys) && !value.empty? ) || ( value.kind_of?(Array) && (value.size > 1 || should_enumerate?(value.first) )))
        end

        def indent_line(string, indent)
          ("  " * indent) << "#{string}\n"
        end

        def indent_key_value(key, value, justify_width, indent)
          lines = value.to_s.split("\n")
          if lines.size > 1
            total_indent = (2 * indent) + justify_width + 1
            indent_line("#{key} #{lines.shift}", indent) << lines.map {|l| (" " * total_indent) + l << "\n" }.join("")
          else
            indent_line("#{key} #{stringify_value(value)}", indent)
          end
        end

        def stringify_value(data)
          data.kind_of?(String) ? data : data.to_s
        end

      end
    end
  end
end

