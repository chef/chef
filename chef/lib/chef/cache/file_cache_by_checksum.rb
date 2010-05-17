#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
  class Cache
    class FileCacheByChecksum
      attr_reader :basedir
      
      def initialize(basedir = Chef::Config[:file_cache_path])
        @basedir = basedir
      end

      # returns path
      def get_path(checksum)
        path = checksum_path(checksum)
        
        File.exists?(path) ? path : nil
      end
      
      # path = path to tempfile as input
      # returns destination path
      def put(checksum, src_path)
        dest_path = checksum_path(checksum)
        FileUtils.mkdir_p(File.dirname(dest_path))
      
        FileUtils.cp(src_path, dest_path)
        
        dest_path
      end
      
      def checksum_path(checksum)
        File.join(basedir, checksum[0..1], checksum)
      end
    end
  end
end
