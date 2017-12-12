
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/provider/package/yum/python_helper"
require "chef/provider/package"
require "singleton"

class Chef
  class Provider
    class Package
      class Yum < Chef::Provider::Package
        # Cache for our installed and available packages, pulled in from yum-dump.py
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

          def available_version(name)
            p = python_helper.package_query(:whatavailable, name)
            "#{p.version}.#{p.arch}"
          end

          def installed_version(name)
            p = python_helper.package_query(:whatinstalled, name)
            "#{p.version}.#{p.arch}"
          end

          private

          def python_helper
            @python_helper ||= PythonHelper.instance
          end

        end # YumCache
      end
    end
  end
end
