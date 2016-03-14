#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Nuo Yan (<yan.nuo@gmail.com>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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

require "chef/knife"
require "chef/cookbook_uploader"

class Chef
  class Knife
    class CookbookUpload < Knife

      CHECKSUM = "checksum"
      MATCH_CHECKSUM = /[0-9a-f]{32,}/

      deps do
        require "chef/exceptions"
        require "chef/cookbook_loader"
        require "chef/cookbook_uploader"
      end

      banner "knife cookbook upload [COOKBOOKS...] (options)"

      option :cookbook_path,
        :short => "-o PATH:PATH",
        :long => "--cookbook-path PATH:PATH",
        :description => "A colon-separated path to look for cookbooks in",
        :proc => lambda { |o| o.split(":") }

      option :freeze,
        :long => "--freeze",
        :description => "Freeze this version of the cookbook so that it cannot be overwritten",
        :boolean => true

      option :all,
        :short => "-a",
        :long => "--all",
        :description => "Upload all cookbooks, rather than just a single cookbook"

      option :force,
        :long => "--force",
        :boolean => true,
        :description => "Update cookbook versions even if they have been frozen"

      option :concurrency,
        :long => "--concurrency NUMBER_OF_THREADS",
        :description => "How many concurrent threads will be used",
        :default => 10,
        :proc => lambda { |o| o.to_i }

      option :environment,
        :short => "-E",
        :long  => "--environment ENVIRONMENT",
        :description => "Set ENVIRONMENT's version dependency match the version you're uploading.",
        :default => nil

      option :depends,
        :short => "-d",
        :long => "--include-dependencies",
        :description => "Also upload cookbook dependencies"

      def run
        # Sanity check before we load anything from the server
        unless config[:all]
          if @name_args.empty?
            show_usage
            ui.fatal("You must specify the --all flag or at least one cookbook name")
            exit 1
          end
        end

        config[:cookbook_path] ||= Chef::Config[:cookbook_path]

        if @name_args.empty? && ! config[:all]
          show_usage
          ui.fatal("You must specify the --all flag or at least one cookbook name")
          exit 1
        end

        assert_environment_valid!
        warn_about_cookbook_shadowing
        version_constraints_to_update = {}
        upload_failures = 0
        upload_ok = 0

        # Get a list of cookbooks and their versions from the server
        # to check for the existence of a cookbook's dependencies.
        @server_side_cookbooks = Chef::CookbookVersion.list_all_versions
        justify_width = @server_side_cookbooks.map { |name| name.size }.max.to_i + 2
        if config[:all]
          cookbook_repo.load_cookbooks_without_shadow_warning
          cookbooks_for_upload = []
          cookbook_repo.each do |cookbook_name, cookbook|
            cookbooks_for_upload << cookbook
            cookbook.freeze_version if config[:freeze]
            version_constraints_to_update[cookbook_name] = cookbook.version
          end
          if cookbooks_for_upload.any?
            begin
              upload(cookbooks_for_upload, justify_width)
            rescue Exceptions::CookbookFrozen
              ui.warn("Not updating version constraints for some cookbooks in the environment as the cookbook is frozen.")
            end
            ui.info("Uploaded all cookbooks.")
          else
            cookbook_path = config[:cookbook_path].respond_to?(:join) ? config[:cookbook_path].join(", ") : config[:cookbook_path]
            ui.warn("Could not find any cookbooks in your cookbook path: #{cookbook_path}. Use --cookbook-path to specify the desired path.")
          end
        else
          if @name_args.empty?
            show_usage
            ui.error("You must specify the --all flag or at least one cookbook name")
            exit 1
          end

          cookbooks_to_upload.each do |cookbook_name, cookbook|
            cookbook.freeze_version if config[:freeze]
            begin
              upload([cookbook], justify_width)
              upload_ok += 1
              version_constraints_to_update[cookbook_name] = cookbook.version
            rescue Exceptions::CookbookNotFoundInRepo => e
              upload_failures += 1
              ui.error("Could not find cookbook #{cookbook_name} in your cookbook path, skipping it")
              Log.debug(e)
              upload_failures += 1
            rescue Exceptions::CookbookFrozen
              ui.warn("Not updating version constraints for #{cookbook_name} in the environment as the cookbook is frozen.")
              upload_failures += 1
            end
          end

          if upload_failures == 0
            ui.info "Uploaded #{upload_ok} cookbook#{upload_ok > 1 ? "s" : ""}."
          elsif upload_failures > 0 && upload_ok > 0
            ui.warn "Uploaded #{upload_ok} cookbook#{upload_ok > 1 ? "s" : ""} ok but #{upload_failures} " +
              "cookbook#{upload_failures > 1 ? "s" : ""} upload failed."
          elsif upload_failures > 0 && upload_ok == 0
            ui.error "Failed to upload #{upload_failures} cookbook#{upload_failures > 1 ? "s" : ""}."
            exit 1
          end
        end

        unless version_constraints_to_update.empty?
          update_version_constraints(version_constraints_to_update) if config[:environment]
        end
      end

      def cookbooks_to_upload
        @cookbooks_to_upload ||=
          if config[:all]
            cookbook_repo.load_cookbooks_without_shadow_warning
          else
            upload_set = {}
            @name_args.each do |cookbook_name|
              begin
                if ! upload_set.has_key?(cookbook_name)
                  upload_set[cookbook_name] = cookbook_repo[cookbook_name]
                  if config[:depends]
                    upload_set[cookbook_name].metadata.dependencies.each { |dep, ver| @name_args << dep }
                  end
                end
              rescue Exceptions::CookbookNotFoundInRepo => e
                ui.error("Could not find cookbook #{cookbook_name} in your cookbook path, skipping it")
                Log.debug(e)
              end
            end
            upload_set
          end
      end

      def cookbook_repo
        @cookbook_loader ||= begin
          Chef::Cookbook::FileVendor.fetch_from_disk(config[:cookbook_path])
          Chef::CookbookLoader.new(config[:cookbook_path])
        end
      end

      def update_version_constraints(new_version_constraints)
        new_version_constraints.each do |cookbook_name, version|
          environment.cookbook_versions[cookbook_name] = "= #{version}"
        end
        environment.save
      end

      def environment
        @environment ||= config[:environment] ? Environment.load(config[:environment]) : nil
      end

      def warn_about_cookbook_shadowing
        # because cookbooks are lazy-loaded, we have to force the loader
        # to load the cookbooks the user intends to upload here:
        cookbooks_to_upload

        unless cookbook_repo.merged_cookbooks.empty?
          ui.warn "* " * 40
          ui.warn(<<-WARNING)
The cookbooks: #{cookbook_repo.merged_cookbooks.join(', ')} exist in multiple places in your cookbook_path.
A composite version of these cookbooks has been compiled for uploading.

#{ui.color('IMPORTANT:', :red, :bold)} In a future version of Chef, this behavior will be removed and you will no longer
be able to have the same version of a cookbook in multiple places in your cookbook_path.
WARNING
          ui.warn "The affected cookbooks are located:"
          ui.output ui.format_for_display(cookbook_repo.merged_cookbook_paths)
          ui.warn "* " * 40
        end
      end

      private

      def assert_environment_valid!
        environment
      rescue Net::HTTPServerException => e
        if e.response.code.to_s == "404"
          ui.error "The environment #{config[:environment]} does not exist on the server, aborting."
          Log.debug(e)
          exit 1
        else
          raise
        end
      end

      def upload(cookbooks, justify_width)
        cookbooks.each do |cb|
          ui.info("Uploading #{cb.name.to_s.ljust(justify_width + 10)} [#{cb.version}]")
          check_for_broken_links!(cb)
          check_for_dependencies!(cb)
        end
        Chef::CookbookUploader.new(cookbooks, :force => config[:force], :concurrency => config[:concurrency]).upload_cookbooks
      rescue Chef::Exceptions::CookbookFrozen => e
        ui.error e
        raise
      end

      def check_for_broken_links!(cookbook)
        # MUST!! dup the cookbook version object--it memoizes its
        # manifest object, but the manifest becomes invalid when you
        # regenerate the metadata
        broken_files = cookbook.dup.manifest_records_by_path.select do |path, info|
          info[CHECKSUM].nil? || info[CHECKSUM] !~ MATCH_CHECKSUM
        end
        unless broken_files.empty?
          broken_filenames = Array(broken_files).map { |path, info| path }
          ui.error "The cookbook #{cookbook.name} has one or more broken files"
          ui.error "This is probably caused by broken symlinks in the cookbook directory"
          ui.error "The broken file(s) are: #{broken_filenames.join(' ')}"
          exit 1
        end
      end

      def check_for_dependencies!(cookbook)
        # for all dependencies, check if the version is on the server, or
        # the version is in the cookbooks being uploaded. If not, exit and warn the user.
        missing_dependencies = cookbook.metadata.dependencies.reject do |cookbook_name, version|
          check_server_side_cookbooks(cookbook_name, version) || check_uploading_cookbooks(cookbook_name, version)
        end

        unless missing_dependencies.empty?
          missing_cookbook_names = missing_dependencies.map { |cookbook_name, version| "'#{cookbook_name}' version '#{version}'" }
          ui.error "Cookbook #{cookbook.name} depends on cookbooks which are not currently"
          ui.error "being uploaded and cannot be found on the server."
          ui.error "The missing cookbook(s) are: #{missing_cookbook_names.join(', ')}"
          exit 1
        end
      end

      def check_server_side_cookbooks(cookbook_name, version)
        if @server_side_cookbooks[cookbook_name].nil?
          false
        else
          versions = @server_side_cookbooks[cookbook_name]["versions"].collect { |versions| versions["version"] }
          Log.debug "Versions of cookbook '#{cookbook_name}' returned by the server: #{versions.join(", ")}"
          @server_side_cookbooks[cookbook_name]["versions"].each do |versions_hash|
            if Chef::VersionConstraint.new(version).include?(versions_hash["version"])
              Log.debug "Matched cookbook '#{cookbook_name}' with constraint '#{version}' to cookbook version '#{versions_hash['version']}' on the server"
              return true
            end
          end
          false
        end
      end

      def check_uploading_cookbooks(cookbook_name, version)
        if (! cookbooks_to_upload[cookbook_name].nil?) && Chef::VersionConstraint.new(version).include?(cookbooks_to_upload[cookbook_name].version)
          Log.debug "Matched cookbook '#{cookbook_name}' with constraint '#{version}' to a local cookbook."
          return true
        end
        false
      end
    end
  end
end
