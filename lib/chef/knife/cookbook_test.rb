#
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# Copyright:: Copyright (c) 2010 Matthew Kent
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
require 'chef/knife'

class Chef
  class Knife
    class CookbookTest < Knife

      deps do
        require 'chef/cookbook/syntax_check'
      end

      banner "knife cookbook test [COOKBOOKS...] (options)"

      option :cookbook_path,
        :short => "-o PATH:PATH",
        :long => "--cookbook-path PATH:PATH",
        :description => "A colon-separated path to look for cookbooks in",
        :proc => lambda { |o| o.split(":") }

      option :all,
        :short => "-a",
        :long => "--all",
        :description => "Test all cookbooks, rather than just a single cookbook"

      def run
        config[:cookbook_path] ||= Chef::Config[:cookbook_path]

        checked_a_cookbook = false
        if config[:all]
          cl = cookbook_loader
          cl.load_cookbooks
          cl.each do |key, cookbook|
            checked_a_cookbook = true
            test_cookbook(key)
          end
        else
          @name_args.each do |cb|
            ui.info "checking #{cb}"
            next unless cookbook_loader.cookbook_exists?(cb)
            checked_a_cookbook = true
            test_cookbook(cb)
          end
        end
        unless checked_a_cookbook
          ui.warn("No cookbooks to test in #{Array(config[:cookbook_path]).join(',')} - is your cookbook path misconfigured?")
        end
      end

      def test_cookbook(cookbook)
        ui.info("Running syntax check on #{cookbook}")
        Array(config[:cookbook_path]).reverse.each do |path|
          syntax_checker = Chef::Cookbook::SyntaxCheck.for_cookbook(cookbook, path)
          test_ruby(syntax_checker)
          test_templates(syntax_checker)
        end
      end


      def test_ruby(syntax_checker)
        ui.info("Validating ruby files")
        exit(1) unless syntax_checker.validate_ruby_files
      end

      def test_templates(syntax_checker)
        ui.info("Validating templates")
        exit(1) unless syntax_checker.validate_templates
      end

      def cookbook_loader
        @cookbook_loader ||= Chef::CookbookLoader.new(config[:cookbook_path])
      end

    end
  end
end
