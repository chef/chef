#
# Author:: Lamont Granquist (<lamont@chef.io>)
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

require_relative "deploy/cp"
require_relative "deploy/mv_unix"
if ChefUtils.windows?
  require_relative "deploy/mv_windows"
end

class Chef
  class FileContentManagement
    class Deploy
      def self.strategy(atomic_update)
        if atomic_update
          ChefUtils.windows? ? MvWindows.new : MvUnix.new
        else
          Cp.new
        end
      end
    end
  end
end
