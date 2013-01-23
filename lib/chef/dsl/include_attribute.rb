#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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

require 'chef/log'

class Chef
  module DSL
    module IncludeAttribute

      # Loads the attribute file specified by the short name of the
      # file, e.g., loads specified cookbook's
      #   "attributes/mailservers.rb"
      # if passed
      #   "mailservers"
      def include_attribute(*attr_file_specs)
        attr_file_specs.flatten.each do |attr_file_spec|
          cookbook_name, attr_file = parse_attribute_file_spec(attr_file_spec)
          if run_context.loaded_fully_qualified_attribute?(cookbook_name, attr_file)
            Chef::Log.debug("I am not loading attribute file #{cookbook_name}::#{attr_file}, because I have already seen it.")
          else
            Chef::Log.debug("Loading Attribute #{cookbook_name}::#{attr_file}")
            run_context.loaded_attribute(cookbook_name, attr_file)
            attr_file_path = run_context.resolve_attribute(cookbook_name, attr_file)
            node.from_file(attr_file_path)
          end
        end
        true
      end

      # Takes a attribute file specification, like "apache2" or "mysql::server"
      # and converts it to a 2 element array of [cookbook_name, attribute_file_name]
      def parse_attribute_file_spec(file_spec)
        if match = file_spec.match(/(.+?)::(.+)/)
          [match[1], match[2]]
        else
          [file_spec, "default"]
        end
      end

    end
  end
end

# **DEPRECATED**
# This used to be part of chef/mixin/language_include_attribute. Load the file to activate the deprecation code.
require 'chef/mixin/language_include_attribute'


