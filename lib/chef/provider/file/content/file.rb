#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/provider/file/content'

class Chef
  class Provider
    class File
      class Content
        class File < Chef::Provider::File::Content
          def file_for_provider
            if @new_resource.content
              tempfile = Tempfile.open(tempfile_basename, tempfile_dirname)
              tempfile.write(@new_resource.content)
              tempfile.close
              tempfile
            else
              nil
            end
          end

          private

          def tempfile_basename
            basename = ::File.basename(@new_resource.name)
            basename.insert 0, "." unless Chef::Platform.windows?  # dotfile if we're not on windows
            basename
          end
        end
      end
    end
  end
end
