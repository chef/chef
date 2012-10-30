#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

class Chef
  class Checksum
    class Storage
      class Filesystem
        def initialize(base_dir, checksum)
          @base_dir = base_dir
          @checksum = checksum
        end

        def file_location
          File.join(checksum_repo_directory, @checksum)
        end
        alias :to_s :file_location

        def checksum_repo_directory
          File.join(Chef::Config.checksum_path, @checksum[0..1])
        end

        def commit(sandbox_file)
          FileUtils.mkdir_p(checksum_repo_directory)
          File.rename(sandbox_file, file_location)
        end

        def revert(original_committed_file_location)
          File.rename(file_location, original_committed_file_location)
        end

        # Deletes the file backing this checksum from the on-disk repo.
        # Purging the checksums is how users can get back to a valid state if
        # they've deleted files, so we silently swallow Errno::ENOENT here.
        def purge
          FileUtils.rm(file_location)
        rescue Errno::ENOENT
          true
        end
      end
    end
  end
end
