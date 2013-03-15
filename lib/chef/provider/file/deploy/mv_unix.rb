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
# PURPOSE: this strategy is atomic, does not mutate file modes, and supports selinux
#
# Note the FileUtils.mv does not have a preserve flag, and the preserve behavior of it is different
# on different rubies (1.8.7 vs 1.9.x) so we are explicit about making certain the tempfile metadata
# is not deployed (technically implementing preserve = false ourselves).
#

class Chef
  class Provider
    class File
      class Deploy
        class MvUnix
          def create(file)
            Chef::Log.debug("touching #{file} to create it")
            FileUtils.touch(file)
          end

          def deploy(src, dst)
            # we are only responsible for content so restore the dst files perms
            Chef::Log.debug("reading modes from #{dst} file")
            mode = ::File.stat(dst).mode & 07777
            uid  = ::File.stat(dst).uid
            gid  = ::File.stat(dst).gid
            Chef::Log.debug("applying mode = #{mode.to_s(8)}, uid = #{uid}, gid = #{gid} to #{src}")
            ::File.chmod(mode, src)
            ::File.chown(uid, gid, src)
            Chef::Log.debug("moving temporary file #{src} into place at #{dst}")
            FileUtils.mv(src, dst)

            # handle selinux if we need to run restorecon
            if Chef::Config[:selinux_enabled]
              Chef::Log.debug("selinux is enabled, fixing selinux permissions")
              cmd = "#{Chef::Config[:selinux_restorecon_comand]} #{dst}"
              shell_out!(cmd)
            end
          end
        end
      end
    end
  end
end
