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
Chef::Config[:persistent_queue] = false
Chef::Config[:file_backup_path] = CHEF_SPEC_BACKUP_PATH

Chef::Log.level(Chef::Config.log_level)
Chef::Config.solo(false)

Chef::Log.logger = Logger.new(StringIO.new)

def sha256_checksum(path)
  Digest::SHA256.hexdigest(File.read(path))
end

# From Ruby 1.9.2+
# Here for backwards compatibility with Ruby 1.8.7
# http://rubydoc.info/stdlib/tmpdir/1.9.2/Dir/Tmpname
def make_tmpname(prefix_suffix, n = nil)
  case prefix_suffix
  when String
    prefix = prefix_suffix
    suffix = ""
  when Array
    prefix = prefix_suffix[0]
    suffix = prefix_suffix[1]
  else
    raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
  end
  t = Time.now.strftime("%Y%m%d")
  path = "#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
  path << "-#{n}" if n
  path << suffix
end

# NOTE:
# This is a temporary fix to get tests passing on systems that have no `diff`
# until we can replace shelling out to `diff` with ruby diff-lcs
def has_diff?
  begin
    diff_cmd = Mixlib::ShellOut.new("diff -v")
    diff_cmd.run_command
    true
  rescue Errno::ENOENT
    false
  end
end

# This is a helper to determine if the ruby in the PATH contains
# win32/service gem. windows_service_manager tests create a windows
# service that starts with the system ruby and requires this gem.
def system_windows_service_gem?
  windows_service_gem_check_command = "ruby -e 'require \"win32/daemon\"' > /dev/null 2>&1"
  if defined?(Bundler)
    Bundler.with_clean_env do
      # This returns true if the gem can be loaded
      system windows_service_gem_check_command
    end
  else
    # This returns true if the gem can be loaded
    system windows_service_gem_check_command
  end
end

# This is a helper to canonicalize paths that we're using in the file
# tests.
def canonicalize_path(path)
  windows? ? path.gsub('/', '\\') : path
end

# Check if a cmd exists on the PATH
def which(cmd)
  paths = ENV['PATH'].split(File::PATH_SEPARATOR) + [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ]
  paths.each do |path|
    filename = File.join(path, cmd)
    return filename if File.executable?(filename)
  end
  false
end
