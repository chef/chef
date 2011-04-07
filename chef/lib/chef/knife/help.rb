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

      def run
        if name_args.size == 1
          @command_name = name_args.first
        elsif name_args.empty?
          ui.info "Usage: knife SUBCOMMAND (options)"
          show_usage
          ui.msg ""
          ui.info "For further help:"
          ui.info(<<-MOAR_HELP)
  knife help categories       list help categories
  knife COMMAND --help        show the options for a command
MOAR_HELP
          exit 1
        else
          ui.error "Please provide just one command category to display help for"
          exit 1
        end

        case @command_name
        when 'categories'
          ui.info "Available help categories are: "
          self.class.subcommands_by_category.keys.sort.each do |category|
            ui.msg "* #{category}"
          end
        else
          manpage_path =  File.expand_path('../distro/common/man/man8/knife.8', CHEF_ROOT)
          exec "man #{manpage_path}"
        end


      end

    end
  end
end
