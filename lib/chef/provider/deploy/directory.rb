#
# Author:: Ameir Abdeldayem (<oss@ameir.net>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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
  class Provider
    class Deploy
      class DeployDirectory < Chef::Provider::Deploy
        provides :deploy_directory

        def initialize(new_resource, run_context)
          super(new_resource, run_context)
        end

        def update_cached_repo
          true
        end

        def load_current_resource
          @release_path = @new_resource.deploy_to + "/releases/#{release_slug}"
          @shared_path = @new_resource.shared_path
        end

        protected

        def release_slug
          Time.now.utc.strftime('%Y%m%d%H%M%S')
        end
      end
    end
  end
end
