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
# PURPOSE: this strategy is atomic, attempts to preserve file modes, and supports selinux
#
# NOTE: there is no a preserve flag to FileUtils.mv, and the complexity here is probably why
#

class Chef
  class Provider
    class File
      class Deploy
        class MvUnix
          def create(file)
            # this is very simple, but it ensures that ownership and file modes take
            # good defaults, in particular mode needs to obey umask on create
            Chef::Log.debug("touching #{file} to create it")
            FileUtils.touch(file)
          end

          def deploy(src, dst)
            # we are only responsible for content so restore the dst files perms
            Chef::Log.debug("reading modes from #{dst} file")
            mode = ::File.stat(dst).mode & 07777
            uid  = ::File.stat(dst).uid
            gid  = ::File.stat(dst).gid

            Chef::Log.debug("moving temporary file #{src} into place at #{dst}")
            FileUtils.mv(src, dst)

            Chef::Log.debug("applying mode = #{mode.to_s(8)}, uid = #{uid}, gid = #{gid} to #{dst}")

            # i own the inode, so should be able to at least chmod it
            ::File.chmod(mode, dst)

            # we may be running as non-root in which case because we are doing an mv we cannot preserve
            # the file modes.  after the mv we have a different inode and if we don't have rights to
            # chown/chgrp on the inode then we can't fix the ownership.
            #
            # in the case where i'm running chef-solo on my homedir as myself and some root-shell
            # work has caused dotfiles of mine to change to root-owned, i'm fine with this not being
            # exceptional, and i think most use cases will consider this to not be exceptional, and
            # the right thing is to fix the ownership of the file to the user running the commmand
            # (which requires write perms to the directory, or mv will have already thrown an exception)
            begin
              ::File.chown(uid, nil, dst)
            rescue Errno::EPERM
              Chef::Log.warn("Could not set uid = #{uid} on #{dst}, file modes not preserved")
            end
            begin
              ::File.chown(nil, gid, dst)
            rescue Errno::EPERM
              Chef::Log.warn("Could not set gid = #{gid} on #{dst}, file modes not preserved")
            end


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
