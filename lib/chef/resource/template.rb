#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2008, 2011 Opscode, Inc.
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

require 'chef/resource/file'
require 'chef/provider/template'
require 'chef/mixin/securable'

class Chef
  class Resource
    class Template < Chef::Resource::File
      include Chef::Mixin::Securable

      provides :template, :on_platforms => :all

      attr_reader :inline_helper_blocks
      attr_reader :inline_helper_modules

      def initialize(name, run_context=nil)
        super
        @resource_name = :template
        @action = "create"
        @source = "#{::File.basename(name)}.erb"
        @cookbook = nil
        @local = false
        @variables = Hash.new
        @provider = Chef::Provider::Template
        @inline_helper_blocks = {}
        @inline_helper_modules = []
        @helper_modules = []
      end

      def source(file=nil)
        set_or_return(
          :source,
          file,
          :kind_of => [ String ]
        )
      end

      def variables(args=nil)
        set_or_return(
          :variables,
          args,
          :kind_of => [ Hash ]
        )
      end

      def cookbook(args=nil)
        set_or_return(
          :cookbook,
          args,
          :kind_of => [ String ]
        )
      end

      def local(args=nil)
        set_or_return(
          :local,
          args,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def helper(method_name, &block)
        unless block_given?
          raise Exceptions::ValidationFailed,
            "`helper(:method)` requires a block argument (e.g., `helper(:method) { code }`)"
        end

        unless method_name.kind_of?(Symbol)
          raise Exceptions::ValidationFailed,
            "method_name argument to `helper(method_name)` must be a symbol (e.g., `helper(:method) { code }`)"
        end

        @inline_helper_blocks[method_name] = block
      end

      def helpers(module_name=nil,&block)
        if block_given? and !module_name.nil?
          raise Exceptions::ValidationFailed,
            "Passing both a module and block to #helpers is not supported. Call #helpers multiple times instead"
        elsif block_given?
          @inline_helper_modules << block
        elsif module_name.kind_of?(::Module)
          @helper_modules << module_name
        elsif module_name.nil?
          raise Exceptions::ValidationFailed,
            "#helpers requires either a module name or inline module code as a block.\n" +
            "e.g.: helpers do; helper_code; end;\n" +
            "OR: helpers(MyHelpersModule)"
        else
          raise Exceptions::ValidationFailed,
            "Argument to #helpers must be a module. You gave #{module_name.inspect} (#{module_name.class})"
        end
      end

      def helper_modules
        compiled_helper_methods + compiled_helper_modules + @helper_modules
      end

      private

      # compiles helper methods into a module that can be included in template context
      def compiled_helper_methods
        if inline_helper_blocks.empty?
          []
        else
          resource_helper_blocks = inline_helper_blocks
          helper_mod = Module.new do
            resource_helper_blocks.each do |method_name, method_body|
              define_method(method_name, &method_body)
            end
          end
          [ helper_mod ]
        end
      end

      def compiled_helper_modules
        @inline_helper_modules.map do |module_body|
          Module.new(&module_body)
        end
      end

    end
  end
end
