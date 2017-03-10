#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
  class FileContentManagement
    class ContentBase

      attr_reader :run_context
      attr_reader :new_resource
      attr_reader :current_resource

      def initialize(new_resource, current_resource, run_context)
        @new_resource = new_resource
        @current_resource = current_resource
        @run_context = run_context
        @tempfile_loaded = false
      end

      def tempfile
        # tempfile may be nil, so we cannot use ||= here
        if @tempfile_loaded
          @tempfile
        else
          @tempfile_loaded = true
          @tempfile = file_for_provider
        end
      end

      private

      #
      # Return something that looks like a File or Tempfile and
      # you must assume the provider will unlink this file.  Copy
      # the contents to a Tempfile if you need to.
      #
      def file_for_provider
        raise "class must implement file_for_provider!"
      end
    end
  end
end
