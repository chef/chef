#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

# == FileUtils::Entry_ (Patch)
# On Ruby 1.9.3 and earlier, FileUtils.cp_r(foo, bar, :preserve => true) fails
# when attempting to copy a directory containing symlinks. This has been
# patched in the trunk of Ruby, and this is a monkey patch of the offending
# code.

unless RUBY_VERSION =~ /^2/
  require 'fileutils'

  class FileUtils::Entry_
    def copy_metadata(path)
      st = lstat()
      if !st.symlink?
        File.utime st.atime, st.mtime, path
      end
      begin
        if st.symlink?
          begin
            File.lchown st.uid, st.gid, path
          rescue NotImplementedError
          end
        else
          File.chown st.uid, st.gid, path
        end
      rescue Errno::EPERM
        # clear setuid/setgid
        if st.symlink?
          begin
            File.lchmod st.mode & 01777, path
          rescue NotImplementedError
          end
        else
          File.chmod st.mode & 01777, path
        end
      else
        if st.symlink?
          begin
            File.lchmod st.mode, path
          rescue NotImplementedError
          end
        else
          File.chmod st.mode, path
        end
      end
    end
  end
end
