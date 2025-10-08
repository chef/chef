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

require_relative "base"

class Chef
  class Provider
    class Package
      module Freebsd
        class Pkgng < Base

          def install_package(name, version)
            unless current_resource.version
              case new_resource.source
              when %r{^(http|ftp|/)}
                shell_out!("pkg", "add", options, new_resource.source, env: { "LC_ALL" => nil }).status
                logger.trace("#{new_resource} installed from: #{new_resource.source}")
              else
                shell_out!("pkg", "install", "-y", options, name, env: { "LC_ALL" => nil }).status
              end
            end
          end

          def remove_package(name, version)
            options_dup = options && options.map { |str| str.sub(repo_regex, "") }.reject!(&:empty?)
            shell_out!("pkg", "delete", "-y", options_dup, "#{name}#{version ? "-" + version : ""}", env: nil).status
          end

          def current_installed_version
            # pkgng up to version 1.15.99.7 returns 70 for pkg not found,
            # later versions return 1
            pkg_info = shell_out!("pkg", "info", new_resource.package_name, env: nil, returns: [0, 1, 70])
            pkg_info.stdout[/^Version +: (.+)$/, 1]
          end

          def candidate_version
            new_resource.source ? file_candidate_version : repo_candidate_version
          end

          private

          def file_candidate_version
            new_resource.source[/#{Regexp.escape(new_resource.package_name)}-(.+)\.txz/, 1]
          end

          def repo_candidate_version
            if options && options.join(" ").match(repo_regex)
              options = $1.split(" ")
            end

            pkg_query = shell_out!("pkg", "rquery", options, "%v", new_resource.package_name, env: nil)
            pkg_query.exitstatus == 0 ? pkg_query.stdout.strip.split('\n').last : nil
          end

          def repo_regex
            /(-r\s?\S+)\b/
          end

        end
      end
    end
  end
end
