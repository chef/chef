#--
# Copyright:: Copyright (c) 2010-2017, Chef Software Inc.
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

require "tmpdir"
require "chef/mixin/shell_out"

class Chef
  class Cookbook
    class GemInstaller
      include Chef::Mixin::ShellOut

      # @return [Chef::EventDispatch::Dispatcher] the client event dispatcher
      attr_accessor :events
      # @return [Chef::CookbookCollection] the cookbook collection
      attr_accessor :cookbook_collection

      def initialize(cookbook_collection, events)
        @cookbook_collection = cookbook_collection
        @events = events
      end

      # Installs the gems into the omnibus gemset.
      #
      def install
        cookbook_gems = Hash.new { |h, k| h[k] = [] }

        cookbook_collection.each do |cookbook_name, cookbook_version|
          cookbook_version.metadata.gems.each do |args|
            cookbook_gems[args.first] += args[1..-1]
          end
        end

        events.cookbook_gem_start(cookbook_gems)

        unless cookbook_gems.empty?
          begin
            Dir.mktmpdir("chef-gem-bundle") do |dir|
              File.open("#{dir}/Gemfile", "w+") do |tf|
                Array(Chef::Config[:rubygems_url] || "https://www.rubygems.org").each do |s|
                  tf.puts "source '#{s}'"
                end
                cookbook_gems.each do |gem_name, args|
                  tf.puts "gem(*#{([gem_name] + args).inspect})"
                end
                tf.close
                Chef::Log.debug("generated Gemfile contents:")
                Chef::Log.debug(IO.read(tf.path))
                so = shell_out!("bundle install", cwd: dir, env: { "PATH" => path_with_prepended_ruby_bin })
                Chef::Log.info(so.stdout)
              end
            end
            Gem.clear_paths
          rescue Exception => e
            events.cookbook_gem_failed(e)
            raise
          end
        end

        events.cookbook_gem_finished
      end

      private

      # path_sanity appends the ruby_bin, but I want the ruby_bin prepended
      def path_with_prepended_ruby_bin
        env_path = ENV["PATH"].dup || ""
        existing_paths = env_path.split(File::PATH_SEPARATOR)
        existing_paths.unshift(RbConfig::CONFIG["bindir"])
        env_path = existing_paths.join(File::PATH_SEPARATOR)
        env_path.encode("utf-8", invalid: :replace, undef: :replace)
      end
    end
  end
end
