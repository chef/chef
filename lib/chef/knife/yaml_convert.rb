#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2020, Chef Software Inc.
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

require "yaml"
require_relative "../knife"
class Chef::Knife::YamlConvert < Chef::Knife

  banner "knife yaml convert YAML_FILENAME"

  def run
    if name_args.empty?
      ui.error("Please specify the file name of a YAML recipe to convert to Ruby")
      exit 1
    elsif name_args.size >= 2
      ui.error("Only one recipe may converted at a time")
      exit 1
    end

    filename = @name_args[0]
    yaml_contents = IO.read(filename)

    if ::YAML.load_stream(yaml_contents).length > 1
      raise ArgumentError, "YAML recipe '#{filename}' contains multiple documents, only one is supported"
    end

    # Unfortunately, per the YAML spec, comments are stripped when we load, so we lose them on conversion
    yaml_hash = ::YAML.safe_load(yaml_contents)
    unless yaml_hash.is_a?(Hash) && yaml_hash.key?("resources")
      raise ArgumentError, "YAML recipe '#{source_file}' must contain a top-level 'resources' hash (YAML sequence), i.e. 'resources:'"
    end

    ruby_contents = []
    ruby_contents << "# Autoconverted recipe from #{filename}"
    ruby_contents << ""

    yaml_hash["resources"].each do |r|
      type = r.delete("type")
      name = r.delete("name")

      ruby_contents << "#{type} \"#{name}\" do"
      r.each do |p|
        ruby_contents << "  #{p.shift} \"#{p.shift}\""
      end
      ruby_contents << "end"
      ruby_contents << ""
    end

    ruby_contents.each do |l|
      puts l
    end
  end
end
