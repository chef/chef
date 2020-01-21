#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2010-2019, Chef Software Inc.
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

require_relative "file"

class Chef
  class Provider
    class CookbookFile < Chef::Provider::File

      provides :cookbook_file

      def initialize(new_resource, run_context)
        @content_class = Chef::Provider::CookbookFile::Content
        super
      end

      def load_current_resource
        @current_resource = Chef::Resource::CookbookFile.new(new_resource.name)
        super
      end

      private

      def managing_content?
        return true if new_resource.checksum
        return true if !new_resource.source.nil? && @action != :create_if_missing

        false
      end

    end
  end
end
