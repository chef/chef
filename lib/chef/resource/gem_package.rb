#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/resource/package"

class Chef
  class Resource
    class GemPackage < Chef::Resource::Package
      resource_name :gem_package

      property :source, [ String, Array ]
      property :clear_sources, [ true, false ], default: false, desired_state: false
      # Sets a custom gem_binary to run for gem commands.
      property :gem_binary, String, desired_state: false

      ##
      # Options for the gem install, either a Hash or a String. When a hash is
      # given, the options are passed to Gem::DependencyInstaller.new, and the
      # gem will be installed via the gems API. When a String is given, the gem
      # will be installed by shelling out to the gem command. Using a Hash of
      # options with an explicit gem_binary will result in undefined behavior.
      property :options, [ String, Hash, Array, nil ], desired_state: false

    end
  end
end
