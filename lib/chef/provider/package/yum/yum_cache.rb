
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "python_helper"
require_relative "../../package"
require "singleton" unless defined?(Singleton)

#
# These are largely historical APIs, the YumCache object no longer exists and this is a
# facade over the python helper class.  It should be considered deprecated-lite and
# no new APIs should be added and should be added to the python_helper instead.
#

class Chef
  class Provider
    class Package
      class Yum < Chef::Provider::Package
        class YumCache
          include Singleton

          def refresh
            python_helper.restart
          end

          def reload
            python_helper.restart
          end

          def reload_installed
            python_helper.restart
          end

          def reload_provides
            python_helper.restart
          end

          def reset
            python_helper.restart
          end

          def reset_installed
            python_helper.restart
          end

          def available_version(name, arch = nil)
            p = python_helper.package_query(:whatavailable, name, arch: arch)
            "#{p.version}.#{p.arch}" unless p.version.nil?
          end

          def installed_version(name, arch = nil)
            p = python_helper.package_query(:whatinstalled, name, arch: arch)
            "#{p.version}.#{p.arch}" unless p.version.nil?
          end

          def package_available?(name, arch = nil)
            p = python_helper.package_query(:whatavailable, name, arch: arch)
            !p.version.nil?
          end

          # NOTE that it is the responsibility of the python_helper to get these APIs correct and
          # we do not do any validation here that the e.g. version or arch matches the requested value
          # (because the bigger issue there is a buggy+broken python_helper -- so don't try to fix those
          # kinds of bugs here)
          def version_available?(name, version, arch = nil)
            p = python_helper.package_query(:whatavailable, name, version: version, arch: arch)
            !p.version.nil?
          end

          # @api private
          def python_helper
            @python_helper ||= PythonHelper.instance
          end

        end # YumCache
      end
    end
  end
end
