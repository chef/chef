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
    class Help < Chef::Knife

      banner "knife help [list|TOPIC]"

      def run
        if name_args.empty?
          ui.info "Usage: knife SUBCOMMAND (options)"
          show_usage
          ui.msg ""
          ui.info "For further help:"
          ui.info(<<-MOAR_HELP)
  knife help list             list help topics
  knife help knife            show general knife help
  knife help TOPIC            display the manual for TOPIC
  knife COMMAND --help        show the options for a command
MOAR_HELP
          exit 1
        else
          @query = name_args.join('-')
        end



        case @query
        when 'topics', 'list'
          print_help_topics
          exit 1
        when 'intro', 'knife'
          @topic = 'knife'
        else
          @topic = find_manpages_for_query(@query)
        end

        manpage_path = available_manpages_by_basename[@topic]
        exec "man #{manpage_path}"
      end

      def help_topics
        available_manpages_by_basename.keys.map {|c| c.sub(/^knife\-/, '')}.sort
      end

      def print_help_topics
        ui.info "Available help topics are: "
        help_topics.each do |topic|
          ui.msg "  #{topic}"
        end
      end

      def find_manpages_for_query(query)
        possibilities = available_manpages_by_basename.keys.select do |manpage|
          ::File.fnmatch("knife-#{query}*", manpage) || ::File.fnmatch("#{query}*", manpage)
        end
        if possibilities.empty?
          ui.error "No help found for '#{query}'"
          ui.msg ""
          print_help_topics
          exit 1
        elsif possibilities.size == 1
          possibilities.first
        else
          ui.info "Multiple help topics match your query. Pick one:"
          ui.highline.choose(*possibilities)
        end
      end

      def available_manpages_by_basename
        @available_manpages_by_basename ||= begin
          available_manpages = Dir[File.expand_path("../distro/common/man/man1/*1", CHEF_ROOT)]
          available_manpages.inject({}) do |map, manpath|
            map[::File.basename(manpath, '.1')] = manpath
            map
          end
        end
      end

    end
  end
end
