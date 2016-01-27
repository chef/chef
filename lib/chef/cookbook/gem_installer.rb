#--
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2010-2015 Chef Software, Inc.
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

require 'tmpdir'
require 'bundler/inline'

class Chef
  class Cookbook
    class GemInstaller
      attr_accessor :cookbook_collection

      def initialize(cookbook_collection)
        @cookbook_collection = cookbook_collection
      end

      def install
        cookbook_gems = []

        cookbook_collection.each do |cookbook_name, cookbook_version|
          cookbook_gems += cookbook_version.metadata.gems
        end

        return if cookbook_gems.empty?

        gemfile(true) do
          source 'https://rubygems.org'
          cookbook_gems.each do |args|
            gem *args
          end
        end
      end

      class ChefBundlerUI < Bundler::UI::Silent
        def confirm(msg, newline = nil)
          Chef::Log.warn("CONFIRM: #{msg}")
        end

        def error(msg, newline = nil)
          Chef::Log.warn("ERROR: #{msg}")
        end
      end
    end
  end
end
