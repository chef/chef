#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Nuo Yan (<yan.nuo@gmail.com>)
# Copyright:: Copyright (c) 2009, 2010 Opscode, Inc.
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

require 'chef/knife'

class Chef
  class Knife
    class CookbookUpload < Knife

      CHECKSUM = "checksum"
      MATCH_CHECKSUM = /[0-9a-f]{32,}/

      deps do
        require 'chef/exceptions'
        require 'chef/cookbook_loader'
        require 'chef/cookbook_uploader'
      end

      banner "knife cookbook upload [COOKBOOKS...] (options)"

      option :cookbook_path,
        :short => "-o PATH:PATH",
        :long => "--cookbook-path PATH:PATH",
        :description => "A colon-separated path to look for cookbooks in",
        :proc => lambda { |o| o.split(":") }

      option :freeze,
        :long => '--freeze',
        :description => 'Freeze this version of the cookbook so that it cannot be overwritten',
        :boolean => true

      option :all,
        :short => "-a",
        :long => "--all",
        :description => "Upload all cookbooks, rather than just a single cookbook"

      option :force,
        :long => '--force',
        :boolean => true,
        :description => "Update cookbook versions even if they have been frozen"

      option :environment,
        :short => '-E',
        :long  => '--environment ENVIRONMENT',
        :description => "Set ENVIRONMENT's version dependency match the version you're uploading.",
        :default => nil

      option :depends,
        :short => "-d",
        :long => "--include-dependencies",
        :description => "Also upload cookbook dependencies"

      def run
        config[:cookbook_path] ||= Chef::Config[:cookbook_path]

        assert_environment_valid!
        warn_about_cookbook_shadowing
        version_constraints_to_update = {}
        # Get a list of cookbooks and their versions from the server
        # for checking existence of dependending cookbooks.
        @server_side_cookbooks = Chef::CookbookVersion.list_all_versions

        if config[:all]
          justify_width = cookbook_repo.cookbook_names.map {|name| name.size}.max.to_i + 2
          cookbook_repo.each do |cookbook_name, cookbook|
            cookbook.freeze_version if config[:freeze]
            begin
              upload(cookbook, justify_width)
              version_constraints_to_update[cookbook_name] = cookbook.version
            rescue Exceptions::CookbookFrozen
              ui.warn("Not updating version constraints for #{cookbook_name} in the environment as the cookbook is frozen.") if config[:environment]
            end
          end
        else
          if @name_args.empty?
            show_usage
            ui.error("You must specify the --all flag or at least one cookbook name")
            exit 1
          end
          justify_width = @name_args.map {|name| name.size }.max.to_i + 2
          @name_args.each do |cookbook_name|
            begin
              cookbook = cookbook_repo[cookbook_name]
              if config[:depends]
                cookbook.metadata.dependencies.each do |dep, versions|
                  @name_args.push dep
                end
              end
              cookbook.freeze_version if config[:freeze]
              begin
                upload(cookbook, justify_width)
                version_constraints_to_update[cookbook_name] = cookbook.version
              rescue Exceptions::CookbookFrozen
                ui.warn("Not updating version constraints for #{cookbook_name} in the environment as the cookbook is frozen.") if config[:environment]
              end
            rescue Exceptions::CookbookNotFoundInRepo => e
              ui.error("Could not find cookbook #{cookbook_name} in your cookbook path, skipping it")
              Log.debug(e)
            end
          end
        end

        ui.info "upload complete"

        unless version_constraints_to_update.empty?
          update_version_constraints(version_constraints_to_update) if config[:environment]
        end
      end

      def cookbook_repo
        @cookbook_loader ||= begin
          Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, config[:cookbook_path]) }
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

      def upload(cookbook, justify_width)
        ui.info("Uploading #{cookbook.name.to_s.ljust(justify_width + 10)} [#{cookbook.version}]")

        check_for_broken_links(cookbook)
        check_dependencies(cookbook)
        Chef::CookbookUploader.new(cookbook, config[:cookbook_path], :force => config[:force]).upload_cookbook
      rescue Net::HTTPServerException => e
        case e.response.code
        when "409"
          ui.error "Version #{cookbook.version} of cookbook #{cookbook.name} is frozen. Use --force to override."
          Log.debug(e)
          raise Exceptions::CookbookFrozen
        else
          raise
        end
      end

      # if only you people wouldn't put broken symlinks in your cookbooks in
      # the first place. ;)
      def check_for_broken_links(cookbook)
        # MUST!! dup the cookbook version object--it memoizes its
        # manifest object, but the manifest becomes invalid when you
        # regenerate the metadata
        broken_files = cookbook.dup.manifest_records_by_path.select do |path, info|
          info[CHECKSUM].nil? || info[CHECKSUM] !~ MATCH_CHECKSUM
        end
        unless broken_files.empty?
          broken_filenames = Array(broken_files).map {|path, info| path}
          ui.error "The cookbook #{cookbook.name} has one or more broken files"
          ui.info "This is probably caused by broken symlinks in the cookbook directory"
          ui.info "The broken file(s) are: #{broken_filenames.join(' ')}"
          exit 1
        end
      end

      def check_dependencies(cookbook)
        # for each dependency, check if the version is on the server, or
        # the version is in the cookbooks being uploaded. If not, exit and warn the user.
        cookbook.metadata.dependencies.each do |cookbook_name, version|
          unless check_server_side_cookbooks(cookbook_name, version) || check_uploading_cookbooks(cookbook_name, version)
            # warn the user and exit
            ui.error "Cookbook #{cookbook.name} depends on cookbook #{cookbook_name} version #{version},"
            ui.error "which is not currently being uploaded and cannot be found on the server."
            exit 1
          end
        end
      end

      def check_server_side_cookbooks(cookbook_name, version)
        if @server_side_cookbooks[cookbook_name].nil?
          false
        else
          versions = @server_side_cookbooks[cookbook_name]['versions'].collect {|versions| versions["version"]}
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
        if config[:all]
          # check from all local cookbooks in the path
          unless cookbook_repo[cookbook_name].nil?
            if Chef::VersionConstraint.new(version).include?(cookbook_repo[cookbook_name].version)
              Log.debug "Matched cookbook '#{cookbook_name}' with constraint '#{version}' to a local cookbook"
              return true
            end
          end
        else
          # check from only those in the command argument
          if @name_args.include?(cookbook_name)
            if Chef::VersionConstraint.new(version).include?(cookbook_repo[cookbook_name].version)
              Log.debug "Matched cookbook '#{cookbook_name}' with constraint '#{version}' to a cookbook on the command line"
              return true
            end
          end
        end
        false
      end

    end
  end
end
