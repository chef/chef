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
require_relative "toml"
require_relative "../json_compat"
autoload :YAML, "yaml"

class Chef
  module DSL
    module RenderHelpers

      # pretty-print a hash as a JSON string
      def render_json(hash)
        JSON.pretty_generate(hash) + "\n"
      end

      # pretty-print a hash as a TOML string
      def render_toml(hash)
        Chef::DSL::Toml::Dumper.new(hash).toml_str
      end

      # pretty-print a hash as a YAML string
      def render_yaml(hash)
        yaml_content = hash.transform_keys(&:to_s).to_yaml
        # above replaces first-level keys with strings, below the rest
        yaml_content.gsub!(" :", " ")
      end

      extend self
    end
  end
end
