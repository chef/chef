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
require 'chef/cache/checksum'

class Chef
  class Knife
    class CookbookTest < Knife

      banner "Sub-Command: cookbook test [COOKBOOKS...] (options)"

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
        if config[:cookbook_path]
          Chef::Config[:cookbook_path] = config[:cookbook_path]
        else
          config[:cookbook_path] = Chef::Config[:cookbook_path]
        end

        if config[:all] 
          cl = Chef::CookbookLoader.new
          cl.each do |cookbook|
            test_cookbook(cookbook.name.to_s)
          end
        else
          @name_args.each do |cb|
            test_cookbook(cb)
          end
        end
      end

      def test_cookbook(cookbook)
        Chef::Log.info("Running syntax check on #{cookbook}")
        Array(config[:cookbook_path]).reverse.each do |path|
          cookbook_dir = File.expand_path(File.join(path, cookbook))
          test_ruby(cookbook_dir)
          test_templates(cookbook_dir)
        end
      end

      def test_ruby(cookbook_dir)
        cache = Chef::Cache::Checksum.instance
        Dir[File.join(cookbook_dir, '**', '*.rb')].each do |ruby_file|
          key = cache.generate_key(ruby_file, "chef-test")
          fstat = File.stat(ruby_file)

          if cache.lookup_checksum(key, fstat) 
            Chef::Log.info("No change in checksum of #{ruby_file}")
          else
            Chef::Log.info("Testing #{ruby_file} for syntax errors...")
            Chef::Mixin::Command.run_command(:command => "ruby -c #{ruby_file}", :output_on_failure => true)
            cache.generate_checksum(key, ruby_file, fstat)
          end
        end
      end

      def test_templates(cookbook_dir)
        cache = Chef::Cache::Checksum.instance
        Dir[File.join(cookbook_dir, '**', '*.erb')].each do |erb_file|
          key = cache.generate_key(erb_file, "chef-test")
          fstat = File.stat(erb_file)

          if cache.lookup_checksum(key, fstat) 
            Chef::Log.info("No change in checksum of #{erb_file}")
          else
            Chef::Log.info("Testing template #{erb_file} for syntax errors...")
            Chef::Mixin::Command.run_command(:command => "sh -c 'erubis -x #{erb_file} | ruby -c'", :output_on_failure => true)
            cache.generate_checksum(key, erb_file, fstat)
          end
        end
      end

    end
  end
end
