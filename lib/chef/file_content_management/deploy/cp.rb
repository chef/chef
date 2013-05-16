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

#
# PURPOSE: This strategy preserves the inode, and will preserve modes + ownership
#          even if the user running chef cannot create that ownership (but has
#          rights to the file).  It is vulnerable to crashes in the middle of
#          writing the file which could result in corruption or zero-length files.
#

class Chef
  class FileContentManagement
    class Deploy
      #
      # PURPOSE: This strategy preserves the inode, and will preserve modes + ownership
      #          even if the user running chef cannot create that ownership (but has
      #          rights to the file).  It is vulnerable to crashes in the middle of
      #          writing the file which could result in corruption or zero-length files.
      #
      class Cp
        def create(file)
          Chef::Log.debug("touching #{file} to create it")
          FileUtils.touch(file)
        end

        def deploy(src, dst)
          Chef::Log.debug("copying temporary file #{src} into place at #{dst}")
          FileUtils.cp(src, dst)
        end
      end
    end
  end
end
