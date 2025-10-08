# Copyright:: Copyright (c) Chef Software Inc.
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

CHEF_SPEC_DATA = File.expand_path(__dir__ + "/../data/")
CHEF_SPEC_ASSETS = File.expand_path(__dir__ + "/../functional/assets/")
CHEF_SPEC_BACKUP_PATH = File.join(Dir.tmpdir, "test-backup-path")

def sha256_checksum(path)
  OpenSSL::Digest.hexdigest("SHA256", File.read(path))
end

# extracted from Ruby < 2.5 to return a unique temp file name without creating it
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

# This is a helper to canonicalize paths that we're using in the file
# tests.
def canonicalize_path(path)
  windows? ? path.tr("/", "\\") : path
end

# Makes a temp directory with a canonical path on any platform.
# Only really needed to work around an issue on Windows where
# Ruby's temp library generates paths with short names.
def make_canonical_temp_directory
  temp_directory = Dir.mktmpdir
  if windows?
    # On Windows, temporary file / directory path names may have shortened
    # subdirectory names due to reliance on the TMP and TEMP environment variables
    # in some Windows APIs and duplicated logic in Ruby's temp file implementation.
    # To work around this in the unit test context, we obtain the long (canonical)
    # path name via a Windows system call so that this path name can be used
    # in expectations that assume the ability to canonically name paths in comparisons.
    # Note that this was not an issue prior to Ruby 2.2 -- with Ruby 2.2,
    # some Chef code started to use long file names, while Ruby's temp file implementation
    # continued to return the shortened names -- this would cause these particular tests to
    # fail if the username happened to be longer than 8 characters.
    Chef::ReservedNames::Win32::File.get_long_path_name(temp_directory)
  else
    temp_directory
  end
end

# Check if a cmd exists on the PATH
def which(cmd)
  paths = ENV["PATH"].split(File::PATH_SEPARATOR) + [ "/bin", "/usr/bin", "/sbin", "/usr/sbin" ]
  paths.each do |path|
    filename = File.join(path, cmd)
    return filename if File.executable?(filename)
  end
  false
end
