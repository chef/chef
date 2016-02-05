#
# Authors:: Richard Manyanza (liseki@nyikacraftsmen.com)
# Copyright:: Copyright 2014-2016, Richard Manyanza
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

require "chef/provider/package/freebsd/base"

class Chef
  class Provider
    class Package
      module Freebsd
        class Pkgng < Base

          def install_package(name, version)
            unless @current_resource.version
              case @new_resource.source
              when /^(http|ftp|\/)/
                shell_out_with_timeout!("pkg add#{expand_options(@new_resource.options)} #{@new_resource.source}", :env => { "LC_ALL" => nil }).status
                Chef::Log.debug("#{@new_resource} installed from: #{@new_resource.source}")

              else
                shell_out_with_timeout!("pkg install -y#{expand_options(@new_resource.options)} #{name}", :env => { "LC_ALL" => nil }).status
              end
            end
          end

          def remove_package(name, version)
            options = @new_resource.options && @new_resource.options.sub(repo_regex, "")
            options && !options.empty? || options = nil
            shell_out_with_timeout!("pkg delete -y#{expand_options(options)} #{name}#{version ? '-' + version : ''}", :env => nil).status
          end

          def current_installed_version
            pkg_info = shell_out_with_timeout!("pkg info \"#{@new_resource.package_name}\"", :env => nil, :returns => [0, 70])
            pkg_info.stdout[/^Version +: (.+)$/, 1]
          end

          def candidate_version
            @new_resource.source ? file_candidate_version : repo_candidate_version
          end

          private

          def file_candidate_version
            @new_resource.source[/#{Regexp.escape(@new_resource.package_name)}-(.+)\.txz/, 1]
          end

          def repo_candidate_version
            if @new_resource.options && @new_resource.options.match(repo_regex)
              options = $1
            end

            pkg_query = shell_out_with_timeout!("pkg rquery#{expand_options(options)} '%v' #{@new_resource.package_name}", :env => nil)
            pkg_query.exitstatus.zero? ? pkg_query.stdout.strip.split(/\n/).last : nil
          end

          def repo_regex
            /(-r\s?\S+)\b/
          end

        end
      end
    end
  end
end
