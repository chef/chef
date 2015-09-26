#--
# Author:: Lamont Granquist <lamont@getchef.io>
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

class Chef
  module Mixin
    module Which
      def which(cmd, opts = {})
        extra_path =
          if opts[:extra_path].nil?
            [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ]
          else
            [ opts[:extra_path] ].flatten
          end
        paths = ENV['PATH'].split(File::PATH_SEPARATOR) + extra_path
        paths.each do |path|
          filename = File.join(path, cmd)
          return filename if File.executable?(Chef.path_to(filename))
        end
        false
      end
    end
  end
end
