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
# PURPOSE: this strategy is atomic and preserves default umasks, but on windows you must
#          not be copying from the temp directory, and will not correctly restore
#          SELinux contexts.
#

class Chef
  class Provider
    class File
      class Deploy
        class MvWindows
          def create(file)
            Chef::Log.debug("touching #{file} to create it")
            FileUtils.touch(file)
          end

          def deploy(src, dst)
            if ::File.dirname(src) != ::File.dirname(dst)
              # internal warning for now - in a Windows/SElinux/ACLs world its better to write
              # a tempfile to your destination directory and then rename it
              Chef::Log.debug("WARNING: moving tempfile across different directories -- this may break permissions")
            end

            # FIXME: save all the windows perms off the dst
            FileUtils.mv(src, dst)
            # FIXME: restore all the windows perms onto the dst

          end
        end
      end
    end
  end
end
