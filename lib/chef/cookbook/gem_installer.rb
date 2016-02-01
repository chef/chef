#--
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2010-2016 Chef Software, Inc.
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
begin
  require "bundler/inline"
rescue LoadError
  raise RuntimeError, "The RFC060 metadata gem feature requires bundler 1.10.0 or greater."
end

class Chef
  class Cookbook
    class GemInstaller
      attr_accessor :events
      attr_accessor :cookbook_collection

      def initialize(cookbook_collection, events)
        @cookbook_collection = cookbook_collection
        @events = events
      end

      def install
        cookbook_gems = []

        cookbook_collection.each do |cookbook_name, cookbook_version|
          cookbook_gems += cookbook_version.metadata.gems
        end

        events.cookbook_gem_start(cookbook_gems)

        unless cookbook_gems.empty?
          begin
            inline_gemfile do
              source "https://rubygems.org"
              cookbook_gems.each do |args|
                gem *args
              end
            end
          rescue Exception => e
            events.cookbook_gem_failed(e)
            raise
          end
        end

        events.cookbook_gem_finished
      end

      class ChefBundlerUI < Bundler::UI::Silent
        attr_accessor :events

        def initialize(events)
          @events = events
          super()
        end

        def confirm(msg, newline = nil)
          # looks like "Installing time_ago_in_words 0.1.1" when installing
          if msg =~ /Installing\s+(\S+)\s+(\S+)/
            events.cookbook_gem_installing($1, $2)
          end
          Chef::Log.info(msg)
        end

        def error(msg, newline = nil)
          Chef::Log.error(msg)
        end

        def debug(msg, newline = nil)
          Chef::Log.debug(msg)
        end

        def info(msg, newline = nil)
          # looks like "Using time_ago_in_words 0.1.1" when using, plus other misc output
          if msg =~ /Using\s+(\S+)\s+(\S+)/
            events.cookbook_gem_using($1, $2)
          end
          Chef::Log.info(msg)
        end

        def warn(msg, newline = nil)
          Chef::Log.warn(msg)
        end
      end

      private

      def inline_gemfile(&block)
        # requires https://github.com/bundler/bundler/pull/4245
        gemfile(true, ui: ChefBundlerUI.new(events), &block)
      rescue ArgumentError  # Method#arity doesn't inspect optional arguments, so we rescue
        # requires bundler 1.10.0
        gemfile(true, &block)
      end
    end
  end
end
