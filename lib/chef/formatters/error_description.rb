#
# Author:: Tyler Cloke (<tyler@chef.io>)
#
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

require "chef/version"

class Chef
  module Formatters
    # == Formatters::ErrorDescription
    # Class for displaying errors on STDOUT.
    class ErrorDescription

      attr_reader :sections

      def initialize(title)
        @title = title
        @sections = []
      end

      def section(heading, text)
        @sections << { heading => (text || "") }
      end

      def display(out)
        out.puts "=" * 80
        out.puts @title, :red
        out.puts "=" * 80
        out.puts "\n"

        sections.each do |section|
          section.each do |heading, text|
            display_section(heading, text, out)
          end
        end
        display_section("System Info:", error_context_info, out)
      end

      def for_json
        {
          "title" => @title,
          "sections" => @sections,
        }
      end

      private

      def display_section(heading, text, out)
        out.puts heading
        out.puts "-" * heading.size
        out.puts text
        out.puts "\n"
      end

      def error_context_info
        context_info = { chef_version: Chef::VERSION }
        if Chef.node
          context_info[:platform] = Chef.node["platform"]
          context_info[:platform_version] = Chef.node["platform_version"]
        end
        # A string like "ruby 2.3.1p112 (2016-04-26 revision 54768) [x86_64-darwin15]"
        context_info[:ruby] = RUBY_DESCRIPTION
        # The argv[0] value.
        context_info[:program_name] = $PROGRAM_NAME
        # This is kind of wonky but it's the only way to get the entry path script.
        context_info[:executable] = File.realpath(caller.last[/^(.*):\d+:in /, 1])
        context_info.map { |k, v| "#{k}=#{v}" }.join("\n")
      end

    end
  end
end
