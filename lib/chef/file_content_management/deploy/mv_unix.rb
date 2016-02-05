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
    class Deploy
      #
      # PURPOSE: this strategy is atomic, and attempts to preserve file modes
      #
      # NOTE: there is no preserve flag to FileUtils.mv, and we want to preserve the dst file
      #       modes rather than the src file modes (preserve = true is what mv does already, we
      #       would like preserve = false which is tricky).
      #
      class MvUnix
        def create(file)
          # this is very simple, but it ensures that ownership and file modes take
          # good defaults, in particular mode needs to obey umask on create
          Chef::Log.debug("Touching #{file} to create it")
          FileUtils.touch(file)
        end

        def deploy(src, dst)
          # we are only responsible for content so restore the dst files perms
          Chef::Log.debug("Reading modes from #{dst} file")
          stat = ::File.stat(dst)
          mode = stat.mode & 07777
          uid  = stat.uid
          gid  = stat.gid

          Chef::Log.debug("Applying mode = #{mode.to_s(8)}, uid = #{uid}, gid = #{gid} to #{src}")

          # i own the inode, so should be able to at least chmod it
          ::File.chmod(mode, src)

          # we may be running as non-root in which case because we are doing an mv we cannot preserve
          # the file modes.  after the mv we have a different inode and if we don't have rights to
          # chown/chgrp on the inode then we can't fix the ownership.
          #
          # in the case where i'm running chef-solo on my homedir as myself and some root-shell
          # work has caused dotfiles of mine to change to root-owned, i'm fine with this not being
          # exceptional, and i think most use cases will consider this to not be exceptional, and
          # the right thing is to fix the ownership of the file to the user running the commmand
          # (which requires write perms to the directory, or mv will throw an exception)
          begin
            ::File.chown(uid, nil, src)
          rescue Errno::EPERM
            Chef::Log.warn("Could not set uid = #{uid} on #{src}, file modes not preserved")
          end
          begin
            ::File.chown(nil, gid, src)
          rescue Errno::EPERM
            Chef::Log.warn("Could not set gid = #{gid} on #{src}, file modes not preserved")
          end

          Chef::Log.debug("Moving temporary file #{src} into place at #{dst}")
          FileUtils.mv(src, dst)
        end
      end
    end
  end
end
