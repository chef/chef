#
# Author:: Christopher Webber (<cwebber@chef.io>)
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

require_relative "../knife"

class Chef
  class Knife
    class SupermarketInstall < Knife

      deps do
        require "chef/exceptions" unless defined?(Chef::Exceptions)
        require "shellwords" unless defined?(Shellwords)
        require "mixlib/archive" unless defined?(Mixlib::Archive)
        require_relative "core/cookbook_scm_repo"
        require "chef/cookbook/metadata" unless defined?(Chef::Cookbook::Metadata)
      end

      banner "knife supermarket install COOKBOOK [VERSION] (options)"
      category "supermarket"

      option :no_deps,
        short: "-D",
        long: "--skip-dependencies",
        boolean: true,
        default: false,
        description: "Skips automatic dependency installation."

      option :cookbook_path,
        short: "-o PATH:PATH",
        long: "--cookbook-path PATH:PATH",
        description: "A colon-separated path to look for cookbooks in.",
        proc: lambda { |o| o.split(":") }

      option :default_branch,
        short: "-B BRANCH",
        long: "--branch BRANCH",
        description: "Default branch to work with.",
        default: "master"

      option :use_current_branch,
        short: "-b",
        long: "--use-current-branch",
        description: "Use the current branch.",
        boolean: true,
        default: false

      option :supermarket_site,
        short: "-m SUPERMARKET_SITE",
        long: "--supermarket-site SUPERMARKET_SITE",
        description: "The URL of the Supermarket site.",
        default: "https://supermarket.chef.io"

      attr_reader :cookbook_name
      attr_reader :vendor_path

      def run
        if config[:cookbook_path]
          Chef::Config[:cookbook_path] = config[:cookbook_path]
        else
          config[:cookbook_path] = Chef::Config[:cookbook_path]
        end

        @cookbook_name = parse_name_args!
        # Check to ensure we have a valid source of cookbooks before continuing
        #
        @install_path = File.expand_path(Array(config[:cookbook_path]).first)
        ui.info "Installing #{@cookbook_name} to #{@install_path}"

        @repo = CookbookSCMRepo.new(@install_path, ui, config)
        # cookbook_path = File.join(vendor_path, name_args[0])
        upstream_file = File.join(@install_path, "#{@cookbook_name}.tar.gz")

        @repo.sanity_check
        unless config[:use_current_branch]
          @repo.reset_to_default_state
          @repo.prepare_to_import(@cookbook_name)
        end

        downloader = download_cookbook_to(upstream_file)
        clear_existing_files(File.join(@install_path, @cookbook_name))
        extract_cookbook(upstream_file, downloader.version)

        # TODO: it'd be better to store these outside the cookbook repo and
        # keep them around, e.g., in ~/Library/Caches on macOS.
        ui.info("Removing downloaded tarball")
        File.unlink(upstream_file)

        if @repo.finalize_updates_to(@cookbook_name, downloader.version)
          unless config[:use_current_branch]
            @repo.reset_to_default_state
          end
          @repo.merge_updates_from(@cookbook_name, downloader.version)
        else
          unless config[:use_current_branch]
            @repo.reset_to_default_state
          end
        end

        unless config[:no_deps]
          preferred_metadata.dependencies.each_key do |cookbook|
            # Doesn't do versions.. yet
            nv = self.class.new
            nv.config = config
            nv.name_args = [ cookbook ]
            nv.run
          end
        end
      end

      def parse_name_args!
        if name_args.empty?
          ui.error("Please specify a cookbook to download and install.")
          exit 1
        elsif name_args.size >= 2
          unless name_args.last.match(/^(\d+)(\.\d+){1,2}$/) && name_args.size == 2
            ui.error("Installing multiple cookbooks at once is not supported.")
            exit 1
          end
        end
        name_args.first
      end

      def download_cookbook_to(download_path)
        downloader = Chef::Knife::SupermarketDownload.new
        downloader.config[:file] = download_path
        downloader.config[:supermarket_site] = config[:supermarket_site]
        downloader.name_args = name_args
        downloader.run
        downloader
      end

      def extract_cookbook(upstream_file, version)
        ui.info("Uncompressing #{@cookbook_name} version #{version}.")
        Mixlib::Archive.new(convert_path(upstream_file)).extract(@install_path, perms: false)
      end

      def clear_existing_files(cookbook_path)
        ui.info("Removing pre-existing version.")
        FileUtils.rmtree(cookbook_path) if File.directory?(cookbook_path)
      end

      def convert_path(upstream_file)
        # converts a Windows path (C:\foo) to a mingw path (/c/foo)
        if ENV["MSYSTEM"] == "MINGW32"
          upstream_file.sub(/^([[:alpha:]]):/, '/\1')
        else
          Shellwords.escape upstream_file
        end
      end

      # Get the preferred metadata path on disk. Chef prefers the metadata.rb
      # over the metadata.json.
      #
      # @raise if there is no metadata in the cookbook
      #
      # @return [Chef::Cookbook::Metadata]
      def preferred_metadata
        md = Chef::Cookbook::Metadata.new

        rb = File.join(@install_path, @cookbook_name, "metadata.rb")
        if File.exist?(rb)
          md.from_file(rb)
          return md
        end

        json = File.join(@install_path, @cookbook_name, "metadata.json")
        if File.exist?(json)
          json = IO.read(json)
          md.from_json(json)
          return md
        end

        raise Chef::Exceptions::MetadataNotFound.new(@install_path, @cookbook_name)
      end
    end
  end
end
