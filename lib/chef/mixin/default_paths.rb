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
#

require "chef-utils/dsl/default_paths" unless defined?(ChefUtils::DSL::DefaultPaths)

class Chef
  module Mixin
    module DefaultPaths
      include ChefUtils::DSL::DefaultPaths

      def enforce_default_paths(env = ENV)
        if Chef::Config[:enforce_default_paths] || Chef::Config[:enforce_path_sanity]
          env["PATH"] = default_paths(env)
        end
      end
    end
  end
end
