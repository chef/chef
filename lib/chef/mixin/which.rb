#--
# Author:: Lamont Granquist <lamont@chef.io>
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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
      def which(cmd, extra_path: nil)
        # NOTE: unnecessarily duplicates function of path_sanity
        extra_path ||= [ "/bin", "/usr/bin", "/sbin", "/usr/sbin" ]
        paths = ENV["PATH"].split(File::PATH_SEPARATOR) + extra_path
        paths.each do |path|
          filename = Chef.path_to(File.join(path, cmd))
          return filename if File.executable?(filename)
        end
        false
      end
    end
  end
end
