#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2011-2019, Chef Software Inc.
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

class Chef
  module Mixin
    # @ deprecated
    module PathSanity
      def enforce_path_sanity(env = ENV)
        if Chef::Config[:enforce_path_sanity]
          env["PATH"] = ChefUtils::DSL::PathSanity.sanitized_path(env)
        end
      end
    end
  end
end
