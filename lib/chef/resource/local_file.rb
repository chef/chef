#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
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

require 'chef/resource/file'
require 'chef/provider/local_file'
require 'chef/mixin/securable'

class Chef
  class Resource
    class LocalFile < Chef::Resource::File
      include Chef::Mixin::Securable

      provides :local_file, :on_platforms => :all

      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::LocalFile
        @resource_name = :local_file
        @allowed_actions.push(:move)
        @source = nil
      end

      def source(source_filename=nil)
        set_or_return(:source, source_filename, :kind_of => String)
      end

    end
  end
end
