#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/provider/file'
require 'chef/deprecation/provider/cookbook_file'
require 'chef/deprecation/warnings'

class Chef
  class Provider
    class CookbookFile < Chef::Provider::File

      extend Chef::Deprecation::Warnings
      include Chef::Deprecation::Provider::CookbookFile
      add_deprecation_warnings_for(Chef::Deprecation::Provider::CookbookFile.instance_methods)

      def initialize(new_resource, run_context)
        @content_class = Chef::Provider::CookbookFile::Content
        super
      end

      def load_current_resource
        @current_resource = Chef::Resource::CookbookFile.new(@new_resource.name)
        super
      end

    end
  end
end

