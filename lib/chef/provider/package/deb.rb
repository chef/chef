#
# Author:: Kapil Chouhan (<kapil.chouhan@msystechnologies.com>)
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

require_relative "../package"

class Chef
  class Provider
    class Package
      module Deb
        def self.included(base)
          base.class_eval do
            use_multipackage_api

            action :reconfig do
              if current_resource.version.nil?
                logger.debug("#{new_resource} is NOT installed - nothing to do")
                return
              end

              unless new_resource.response_file
                logger.debug("#{new_resource} no response_file provided - nothing to do")
                return
              end

              if preseed_file = get_preseed_file(new_resource.package_name, current_resource.version)
                converge_by("reconfigure package #{new_resource.package_name}") do
                  preseed_package(preseed_file)
                  multipackage_api_adapter(new_resource.package_name, current_resource.version) do |name, _version|
                    reconfig_package(name)
                  end
                  logger.info("#{new_resource} reconfigured")
                end
              else
                logger.debug("#{new_resource} preseeding has not changed - nothing to do")
              end
            end

            # This method is used for getting preseed file
            # it will return preseed file path or false if response_file is present
            def prepare_for_installation
              if new_resource.response_file && preseed_file = get_preseed_file(package_names_for_targets, versions_for_targets)
                converge_by("preseed package #{package_names_for_targets}") do
                  preseed_package(preseed_file)
                end
              end
            end

            def get_preseed_file(name, version)
              resource = preseed_resource(name, version)
              resource.run_action(:create)
              logger.trace("#{new_resource} fetched preseed file to #{resource.path}")

              if resource.updated_by_last_action?
                resource.path
              else
                false
              end
            end

            def preseed_resource(name, version)
              # A directory in our cache to store this cookbook's preseed files in
              file_cache_dir = Chef::FileCache.create_cache_path("preseed/#{new_resource.cookbook_name}")
              # The full path where the preseed file will be stored
              cache_seed_to = "#{file_cache_dir}/#{name}-#{version}.seed"

              logger.trace("#{new_resource} fetching preseed file to #{cache_seed_to}")

              if template_available?(new_resource.response_file)
                logger.trace("#{new_resource} fetching preseed file via Template")
                remote_file = Chef::Resource::Template.new(cache_seed_to, run_context)
                remote_file.variables(new_resource.response_file_variables)
              elsif cookbook_file_available?(new_resource.response_file)
                logger.trace("#{new_resource} fetching preseed file via cookbook_file")
                remote_file = Chef::Resource::CookbookFile.new(cache_seed_to, run_context)
              else
                message = "No template or cookbook file found for response file #{new_resource.response_file}"
                raise Chef::Exceptions::FileNotFound, message
              end

              remote_file.cookbook_name = new_resource.cookbook_name
              remote_file.source(new_resource.response_file)
              remote_file.backup(false)
              remote_file
            end

            def preseed_package(preseed_file)
              logger.info("#{new_resource} pre-seeding package installation instructions")
              run_noninteractive("debconf-set-selections", preseed_file)
            end

            def reconfig_package(name)
              logger.info("#{new_resource} reconfiguring")
              run_noninteractive("dpkg-reconfigure", *name)
            end

            # Runs command via shell_out with magic environment to disable
            # interactive prompts.
            def run_noninteractive(*command)
              shell_out!(*command, env: { "DEBIAN_FRONTEND" => "noninteractive" })
            end

            private

            def template_available?(path)
              run_context.has_template_in_cookbook?(new_resource.cookbook_name, path)
            end

            def cookbook_file_available?(path)
              run_context.has_cookbook_file_in_cookbook?(new_resource.cookbook_name, path)
            end
          end
        end
      end
    end
  end
end
