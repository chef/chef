#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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
  module Formatters
    module ErrorInspectors

      # == CompileErrorInspector
      # Wraps exceptions that occur during the compile phase of a Chef run and
      # tries to find the code responsible for the error.
      class CompileErrorInspector

        attr_reader :path
        attr_reader :exception

        def initialize(path, exception)
          @path, @exception = path, exception
          @backtrace_lines_in_cookbooks = nil
          @file_lines = nil
          @culprit_backtrace_entry = nil
          @culprit_line = nil
        end

        def add_explanation(error_description)
          error_description.section(exception.class.name, exception.message)

          if found_error_in_cookbooks?
            traceback = filtered_bt.map { |line| "  #{line}" }.join("\n")
            error_description.section("Cookbook Trace:", traceback)
            error_description.section("Relevant File Content:", context)
          end

          if exception_message_modifying_frozen?
            msg = <<-MESSAGE
            Ruby objects are often frozen to prevent further modifications
            when they would negatively impact the process (e.g. values inside
            Ruby's ENV class) or to prevent polluting other objects when default
            values are passed by reference to many instances of an object (e.g.
            the empty Array as a Chef resource default, passed by reference
            to every instance of the resource).

            Chef uses Object#freeze to ensure the default values of properties
            inside Chef resources are not modified, so that when a new instance
            of a Chef resource is created, and Object#dup copies values by
            reference, the new resource is not receiving a default value that
            has been by a previous instance of that resource.

            Instead of modifying an object that contains a default value for all
            instances of a Chef resource, create a new object and assign it to
            the resource's parameter, e.g.:

            fruit_basket = resource(:fruit_basket, 'default')

            # BAD: modifies 'contents' object for all new fruit_basket instances
            fruit_basket.contents << 'apple'

            # GOOD: allocates new array only owned by this fruit_basket instance
            fruit_basket.contents %w(apple)

            MESSAGE

            error_description.section("Additional information:", msg.gsub(/^ {6}/, ""))
          end
        end

        def context
          context_lines = []
          context_lines << "#{culprit_file}:\n\n"
          Range.new(display_lower_bound, display_upper_bound).each do |i|
            line_nr = (i + 1).to_s.rjust(3)
            indicator = (i + 1) == culprit_line ? ">> " : ":  "
            context_lines << "#{line_nr}#{indicator}#{file_lines[i]}"
          end
          context_lines.join("")
        end

        def display_lower_bound
          lower = (culprit_line - 8)
          lower = 0 if lower < 0
          lower
        end

        def display_upper_bound
          upper = (culprit_line + 8)
          upper = file_lines.size if upper > file_lines.size
          upper
        end

        def file_lines
          @file_lines ||= IO.readlines(culprit_file)
        end

        def culprit_backtrace_entry
          @culprit_backtrace_entry ||= begin
            bt_entry = filtered_bt.first
            Chef::Log.debug("Backtrace entry for compile error: '#{bt_entry}'")
            bt_entry
          end
        end

        def culprit_line
          @culprit_line ||= begin
            line_number = culprit_backtrace_entry[/^(?:.\:)?[^:]+:([\d]+)/, 1].to_i
            Chef::Log.debug("Line number of compile error: '#{line_number}'")
            line_number
          end
        end

        def culprit_file
          @culprit_file ||= culprit_backtrace_entry[/^((?:.\:)?[^:]+):([\d]+)/, 1]
        end

        def filtered_bt
          backtrace_lines_in_cookbooks.count > 0 ? backtrace_lines_in_cookbooks : exception.backtrace
        end

        def found_error_in_cookbooks?
          !backtrace_lines_in_cookbooks.empty?
        end

        def backtrace_lines_in_cookbooks
          @backtrace_lines_in_cookbooks ||=
            begin
              filters = Array(Chef::Config.cookbook_path).map { |p| /^#{Regexp.escape(p)}/i }
              r = exception.backtrace.select { |line| filters.any? { |filter| line =~ filter } }
              Chef::Log.debug("Filtered backtrace of compile error: #{r.join(",")}")
              r
            end
        end

        def exception_message_modifying_frozen?
          exception.message.include?("can't modify frozen")
        end

      end

    end
  end
end
