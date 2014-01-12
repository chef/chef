#
# Copyright:: Copyright (c) 2013 Noah Kantrowitz <noah@coderanger.net>
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

require 'chef/exceptions'
require 'chef/resource/chef_gem'

class Chef
  class Dialect

    # Class methods to handle registering and finding dialects
    class << self
      def dialects
        @dialects ||= []
      end

      def register_dialect(flavor, extension, mime_type, quality=1)
        Chef::Dialect.dialects << {:extension => extension, :mime_type => mime_type, :quality => quality, :flavor => flavor, :dialect => self}
      end

      def find_by_extension(run_context, flavor, extension)
        # Allow passing in a full file path for ease-of-use
        extension = File.basename(extension)
        extname = File.extname(extension)
        extension = extname if extname != ''
        flavor = flavor.to_sym
        find(run_context) {|d| d[:flavor] == flavor && d[:extension] == extension}
      end

      def find_by_mime_type(run_context, flavor, mime_type)
        flavor = flavor.to_sym
        find(run_context) {|d| d[:flavor] == flavor && d[:mime_type] == mime_type}
      end

      def cleanup
        dialect_instances.each_value {|instance| instance.cleanup}
        dialect_instances.clear
      end

      private

      def dialect_instances
        @dialect_instances ||= {}
      end

      def find(run_context, &block)
        candidates = dialects.select(&block)
        raise Chef::Exceptions::DialectNotFound.new("No matching dialect found") if candidates.empty?
        data = candidates.max_by{|d| d[:quality]}
        dialect = data[:dialect]
        unless dialect_instances[dialect] && dialect_instances[dialect].run_context === run_context
          dialect_instances[dialect] = dialect.new(run_context)
        end
        dialect_instances[dialect]
      end
    end

    attr_reader :run_context

    def initialize(run_context)
      @run_context = run_context
    end

    def install_gem(name, version = nil)
      # This is a no-op for non-run situations like in knife
      return unless @run_context
      # Create a mini-converge to install a single gem into the Chef Ruby env
      res = Chef::Resource::ChefGem.new(name, @run_context)
      res.version(version) if version
      res.after_created
    end

    def cleanup
      # Override for any per-run cleanup logic
    end

    def compile_recipe(recipe, filename)
      raise NotImplementedError
    end

    def compile_attributes(node, filename)
      raise NotImplementedError
    end

  end
end

