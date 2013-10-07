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

require 'chef/dialect'

class Chef::Dialect::DeclarativeBase < Chef::Dialect
  def compile_attributes(node, filename)
    attributes = parse_file(filename)
    # Process both "set" and "normal" even though they are alises on the node
    %w{default normal set override}.each do |level|
      level_data = attributes.delete(level)
      if level_data
        node.send(level).update(level_data)
      end
    end
    node.default.update(attributes)
  end

  def compile_role(klass, filename)
    klass.json_create(parse_file(filename))
  end

  private

  def parse_file(filename)
    if File.exists?(filename) && File.readable?(filename)
      parse_data(IO.read(filename), filename)
    else
      raise IOError, "Cannot open or read #{filename}!"
    end
  end

  def parse_data(data, filename)
    raise NotImplementedError
  end
end
