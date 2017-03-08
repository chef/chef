#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
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

require "chef/provider/file"

class Chef
  class Provider
    class RemoteFile < Chef::Provider::File
      provides :remote_file

      def initialize(new_resource, run_context)
        @content_class = Chef::Provider::RemoteFile::Content
        super
      end

      def load_current_resource
        @current_resource = Chef::Resource::RemoteFile.new(new_resource.name)
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
