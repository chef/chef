#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'stringio'
require "awesome_print"

# Wrapper class for interacting with Ruby.

class Chef
  class RubyCompat

    def self.to_ruby(data)

      case data
      when Chef::Role
        role_to_ruby(data)
      when Chef::Environment
        environment_to_ruby(data)
      else
        raise ArgumentError, "[#{data.class.name}] is not supported by ruby format"
      end

    end

    private

    def self.role_to_ruby(role)
      ruby = RubyIO.new

      # Name
      ruby.method("name", role.name)
      ruby.new_line

      # Description
      ruby.method("description", role.description)
      ruby.new_line

      # Default Attributes
      ruby.method("default_attributes", role.default_attributes)
      ruby.new_line

      # Override Attributes
      ruby.method("override_attributes", role.override_attributes)
      ruby.new_line

      # Run list
      if role.env_run_lists.size <= 1
        ruby.method("run_list", *role.run_list.map{|val| val.to_s})
      else
        ruby.method("env_run_lists", Hash[role.env_run_lists.map{|k, v| [k, v.map{|val| val.to_s}]}])
      end
      ruby.new_line

      ruby.string
    end

    def self.environment_to_ruby(environment)
      ruby = RubyIO.new

      # Name
      ruby.method("name",  environment.name)
      ruby.new_line

      # Description
      ruby.method("description", environment.description)
      ruby.new_line

      # Cookbook versions
      environment.cookbook_versions.each do |cookbook, version_constraint|
        ruby.method("cookbook", cookbook, version_constraint)
      end
      ruby.new_line

      # Default Attributes
      ruby.method("default_attributes", environment.default_attributes)
      ruby.new_line

      # Override Attributes
      ruby.method("override_attributes", environment.override_attributes)
      ruby.new_line

      ruby.string
    end

    class RubyIO

      @@inspector =AwesomePrint::Inspector.new :plain => true, :indent => 2, :index => false

      def initialize
        @out = StringIO.new
      end

      def method(method_name, *args)
        write method_name
        write("(")

        arg_values = args.map do |arg|
          if arg.is_a? String
            arg.inspect
          elsif arg.is_a? Hash
            format(arg)
          else
            raise "Object type [#{arg.class.name}] is not supported"
          end
        end

        write(arg_values.join(", "))

        write(")")

        new_line
      end

      def new_line
        write "\n"
      end

      def write(string)
        @out.write string
      end

      def string
        @out.string
      end

      def format(obj)
        @@inspector.awesome obj
      end

    end

  end
end
