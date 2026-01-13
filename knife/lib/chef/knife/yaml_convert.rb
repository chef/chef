#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) Chef Software Inc.
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

autoload :YAML, "yaml"
require_relative "../knife"
class Chef::Knife::YamlConvert < Chef::Knife

  banner "knife yaml convert YAML_FILENAME [RUBY_FILENAME]"

  def run
    if name_args.empty?
      ui.fatal!("Please specify the file name of a YAML recipe to convert to Ruby")
    elsif name_args.size >= 3
      ui.fatal!("knife yaml convert YAML_FILENAME [RUBY_FILENAME]")
    end

    yaml_file = @name_args[0]
    unless ::File.exist?(yaml_file) && ::File.readable?(yaml_file)
      ui.fatal("Input YAML file '#{yaml_file}' does not exist or is unreadable")
    end

    ruby_file = if @name_args[1]
                  @name_args[1] # use the specified output filename if provided
                else
                  if ::File.extname(yaml_file) == ".yml" || ::File.extname(yaml_file) == ".yaml"
                    yaml_file.gsub(/\.(yml|yaml)$/, ".rb")
                  else
                    yaml_file + ".rb" # fall back to putting .rb on the end of whatever the yaml file was named
                  end
                end

    if ::File.exist?(ruby_file)
      ui.fatal!("Output Ruby file '#{ruby_file}' already exists")
    end

    yaml_contents = IO.read(yaml_file)

    # YAML can contain multiple documents (--- is the separator), let's not support that.
    if ::YAML.load_stream(yaml_contents).length > 1
      ui.fatal!("YAML recipe '#{yaml_file}' contains multiple documents, only one is supported")
    end

    # Unfortunately, per the YAML spec, comments are stripped when we load, so we lose them on conversion
    yaml_hash = ::YAML.safe_load(yaml_contents, permitted_classes: [Symbol])
    unless yaml_hash.is_a?(Hash) && yaml_hash.key?("resources")
      ui.fatal!("YAML recipe '#{source_file}' must contain a top-level 'resources' hash (YAML sequence), i.e. 'resources:'")
    end

    ui.warn("No resources found in '#{yaml_file}'") if yaml_hash["resources"].size == 0

    ::File.open(ruby_file, "w") do |file|
      file.write(resource_hash_to_string(yaml_hash["resources"], yaml_file))
    end
    ui.info("Converted '#{yaml_file}' to '#{ruby_file}'")
  end

  # Converts a Hash of resources to a Ruby recipe
  # returns a string ready to be written to a file or stdout
  def resource_hash_to_string(resource_hash, filename)
    ruby_contents = []
    ruby_contents << "# Autoconverted recipe from #{filename}\n"

    resource_hash.each do |r|
      type = r.delete("type")
      name = r.delete("name")

      ruby_contents << "#{type} \"#{name}\" do"
      r.each do |k, v|
        ruby_contents << "  #{k} #{v.inspect}"
      end
      ruby_contents << "end\n"
    end

    ruby_contents.join("\n")
  end
end
