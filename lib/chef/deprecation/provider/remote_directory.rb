#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2013-2015 Chef Software, Inc.
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
  module Deprecation
    module Provider
      module RemoteDirectory

        def directory_root_in_cookbook_cache
          Chef::Log.deprecation "the Chef::Provider::RemoteDirectory#directory_root_in_cookbook_cache method is deprecated"

          @directory_root_in_cookbook_cache ||=
            begin
              cookbook = run_context.cookbook_collection[resource_cookbook]
              cookbook.preferred_filename_on_disk_location(node, :files, source, path)
            end
        end

        # List all excluding . and ..
        def ls(path)
          files = Dir.glob(::File.join(Chef::Util::PathHelper.escape_glob(path), '**', '*'),
                           ::File::FNM_DOTMATCH)

          # Remove current directory and previous directory
          files = files.reject do |name|
            basename = Pathname.new(name).basename().to_s
            ['.', '..'].include?(basename)
          end

          # Clean all the paths... this is required because of the join
          files.map {|f| Chef::Util::PathHelper.cleanpath(f)}
        end

      end
    end
  end
end
