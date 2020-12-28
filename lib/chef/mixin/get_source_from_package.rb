# Author:: Lamont Granquist (<lamont@chef.io>)
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

#
# mixin to make this syntax work without specifying a source:
#
# gem_package "/tmp/foo-x.y.z.gem"
# rpm_package "/tmp/foo-x.y-z.rpm"
# dpkg_package "/tmp/foo-x.y.z.deb"
#

class Chef
  module Mixin
    module GetSourceFromPackage
      # FIXME:  this is some bad code that I wrote a long time ago.
      #  - it does too much in the initializer
      #  - it mutates the new_resource
      #  - it does not support multipackage arrays
      # this code is deprecated, check out the :use_package_names_for_source
      # subclass directive instead
      def initialize(new_resource, run_context)
        super
        return if new_resource.package_name.is_a?(Array)

        # if we're passed something that looks like a filesystem path, with no source, use it
        #  - require at least one '/' in the path to avoid gem_package "foo" breaking if a file named 'foo' exists in the cwd
        if new_resource.source.nil? && new_resource.package_name.include?(::File::SEPARATOR) && ::File.exist?(new_resource.package_name)
          Chef::Log.trace("No package source specified, but #{new_resource.package_name} exists on the filesystem, copying to package source")
          new_resource.source(new_resource.package_name)
        end
      end
    end
  end
end
