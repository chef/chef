#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

autoload :TOML, "tomlrb"
require_relative "../json_compat"
autoload :YAML, "yaml"

class Chef
  module DSL
    module ReaderHelpers

      def parse_file(filename)
        case File.extname(filename)
        when ".toml"
          parse_toml(filename)
        when ".yaml", ".yml"
          parse_yaml(filename)
        when ".json"
          parse_json(filename)
        else
          raise "Expected TOML, JSON, or YAML when parsing #{filename}"
        end
      end

      def parse_json(filename)
        JSONCompat.parse(IO.read(filename))
      end

      def parse_toml(filename)
        Tomlrb.load_file(filename)
      end

      def parse_yaml(filename)
        YAML.safe_load_file(filename, permitted_classes: [Date])
      end

      extend self
    end
  end
end
