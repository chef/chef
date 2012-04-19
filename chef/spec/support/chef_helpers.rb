# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
CHEF_SPEC_DATA = File.expand_path(File.dirname(__FILE__) + "/../data/")
CHEF_SPEC_BACKUP_PATH = File.join(Dir.tmpdir, 'test-backup-path')

Chef::Config[:log_level] = :fatal
Chef::Config[:cache_type] = "Memory"
Chef::Config[:cache_options] = { }
Chef::Config[:persistent_queue] = false
Chef::Config[:file_backup_path] = CHEF_SPEC_BACKUP_PATH

Chef::Log.level(Chef::Config.log_level)
Chef::Config.solo(false)

Chef::Log.logger = Logger.new(StringIO.new)

def sha256_checksum(path)
  Digest::SHA256.hexdigest(File.read(path))
end
