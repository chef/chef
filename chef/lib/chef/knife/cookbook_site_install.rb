#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

    class CookbookSiteInstall < Knife

      deps do
        require 'chef/mixin/shell_out'
        require 'chef/knife/core/cookbook_scm_repo'
        require 'chef/cookbook/metadata'
      end

      banner "knife cookbook site install COOKBOOK [VERSION] (options)"
      category "cookbook site"

      option :no_deps,
       :short => "-D",
       :long => "--skip-dependencies",
       :boolean => true,
       :default => false,
       :description => "Skips automatic dependency installation."

      option :cookbook_path,
        :short => "-o PATH:PATH",
        :long => "--cookbook-path PATH:PATH",
        :description => "A colon-separated path to look for cookbooks in",
        :proc => lambda { |o| o.split(":") }

      option :default_branch,
        :short => "-B BRANCH",
        :long => "--branch BRANCH",
        :description => "Default branch to work with",
        :default => "master"

      attr_reader :cookbook_name
      attr_reader :vendor_path

      def run
        extend Chef::Mixin::ShellOut

        if config[:cookbook_path]
          Chef::Config[:cookbook_path] = config[:cookbook_path]
        else
          config[:cookbook_path] = Chef::Config[:cookbook_path]
        end

        @cookbook_name = parse_name_args!
        # Check to ensure we have a valid source of cookbooks before continuing
        #
        @install_path = File.expand_path(config[:cookbook_path].first)
        ui.info "Installing #@cookbook_name to #{@install_path}"

        @repo = CookbookSCMRepo.new(@install_path, ui, config)
        #cookbook_path = File.join(vendor_path, name_args[0])
        upstream_file = File.join(@install_path, "#{@cookbook_name}.tar.gz")

        @repo.sanity_check
        @repo.reset_to_default_state
        @repo.prepare_to_import(@cookbook_name)

        downloader = download_cookbook_to(upstream_file)
        clear_existing_files(File.join(@install_path, @cookbook_name))
        extract_cookbook(upstream_file, @install_path)

        # TODO: it'd be better to store these outside the cookbook repo and
        # keep them around, e.g., in ~/Library/Caches on OS X.
        ui.info("removing downloaded tarball")
        File.unlink(upstream_file)

        if @repo.finalize_updates_to(@cookbook_name, downloader.version)
          @repo.reset_to_default_state
          @repo.merge_updates_from(@cookbook_name, downloader.version)
        else
          @repo.reset_to_default_state
        end


        unless config[:no_deps]
          md = Chef::Cookbook::Metadata.new
          md.from_file(File.join(@install_path, @cookbook_name, "metadata.rb"))
          md.dependencies.each do |cookbook, version_list|
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
          ui.error("please specify a cookbook to download and install")
          exit 1
        elsif name_args.size > 1
          ui.error("Installing multiple cookbooks at once is not supported")
          exit 1
        else
          name_args.first
        end
      end

      def download_cookbook_to(download_path)
        downloader = Chef::Knife::CookbookSiteDownload.new
        downloader.config[:file] = download_path
        downloader.name_args = name_args
        downloader.run
        downloader
      end

      def extract_cookbook(upstream_file, version)
        ui.info("Uncompressing #{@cookbook_name} version #{version}.")
        shell_out!("tar zxvf #{upstream_file}", :cwd => @install_path)
      end

      def clear_existing_files(cookbook_path)
        ui.info("Removing pre-existing version.")
        FileUtils.rmtree(cookbook_path) if File.directory?(cookbook_path)
      end
    end
  end
end






