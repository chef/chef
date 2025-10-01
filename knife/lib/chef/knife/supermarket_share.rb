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
    class SupermarketShare < Knife

      include Chef::Mixin::ShellOut

      deps do
        require "chef/cookbook_loader" unless defined?(Chef::CookbookLoader)
        require "chef/cookbook_uploader" unless defined?(Chef::CookbookUploader)
        require "chef/knife/core/cookbook_site_streaming_uploader" unless defined?(Chef::Knife::Core::CookbookSiteStreamingUploader)
        require "chef/mixin/shell_out" unless defined?(Chef::Mixin::ShellOut)
      end

      banner "knife supermarket share COOKBOOK [CATEGORY] (options)"
      category "supermarket"

      option :cookbook_path,
        short: "-o PATH:PATH",
        long: "--cookbook-path PATH:PATH",
        description: "A colon-separated path to look for cookbooks in.",
        proc: lambda { |o| Chef::Config.cookbook_path = o.split(":") }

      option :dry_run,
        long: "--dry-run",
        short: "-n",
        boolean: true,
        default: false,
        description: "Don't take action, only print what files will be uploaded to Supermarket."

      option :supermarket_site,
        short: "-m SUPERMARKET_SITE",
        long: "--supermarket-site SUPERMARKET_SITE",
        description: "The URL of the Supermarket site.",
        default: "https://supermarket.chef.io"

      def run
        config[:cookbook_path] ||= Chef::Config[:cookbook_path]

        if @name_args.length < 1
          show_usage
          ui.fatal("You must specify the cookbook name.")
          exit(1)
        elsif @name_args.length < 2
          cookbook_name = @name_args[0]
          category = get_category(cookbook_name)
        else
          cookbook_name = @name_args[0]
          category = @name_args[1]
        end

        cl = Chef::CookbookLoader.new(config[:cookbook_path])
        if cl.cookbook_exists?(cookbook_name)
          cookbook = cl[cookbook_name]
          Chef::CookbookUploader.new(cookbook).validate_cookbooks
          tmp_cookbook_dir = Chef::Knife::Core::CookbookSiteStreamingUploader.create_build_dir(cookbook)
          begin
            Chef::Log.trace("Temp cookbook directory is #{tmp_cookbook_dir.inspect}")
            ui.info("Making tarball #{cookbook_name}.tgz")
            shell_out!("#{tar_cmd} -czf #{cookbook_name}.tgz #{cookbook_name}", cwd: tmp_cookbook_dir)
          rescue => e
            ui.error("Error making tarball #{cookbook_name}.tgz: #{e.message}. Increase log verbosity (-VV) for more information.")
            Chef::Log.trace("\n#{e.backtrace.join("\n")}")
            exit(1)
          end

          if config[:dry_run]
            ui.info("Not uploading #{cookbook_name}.tgz due to --dry-run flag.")
            result = shell_out!("#{tar_cmd} -tzf #{cookbook_name}.tgz", cwd: tmp_cookbook_dir)
            ui.info(result.stdout)
            FileUtils.rm_rf tmp_cookbook_dir
            return
          end

          begin
            do_upload("#{tmp_cookbook_dir}/#{cookbook_name}.tgz", category, Chef::Config[:node_name], Chef::Config[:client_key])
            ui.info("Upload complete")
            Chef::Log.trace("Removing local staging directory at #{tmp_cookbook_dir}")
            FileUtils.rm_rf tmp_cookbook_dir
          rescue => e
            ui.error("Error uploading cookbook #{cookbook_name} to Supermarket: #{e.message}. Increase log verbosity (-VV) for more information.")
            Chef::Log.trace("\n#{e.backtrace.join("\n")}")
            exit(1)
          end

        else
          ui.error("Could not find cookbook #{cookbook_name} in your cookbook path.")
          exit(1)
        end
      end

      def get_category(cookbook_name)
        data = noauth_rest.get("#{config[:supermarket_site]}/api/v1/cookbooks/#{@name_args[0]}")
        data["category"]
      rescue => e
        return "Other" if e.is_a?(Net::HTTPClientException) && e.response.code == "404"

        ui.fatal("Unable to reach Supermarket: #{e.message}. Increase log verbosity (-VV) for more information.")
        Chef::Log.trace("\n#{e.backtrace.join("\n")}")
        exit(1)
      end

      def do_upload(cookbook_filename, cookbook_category, user_id, user_secret_filename)
        uri = "#{config[:supermarket_site]}/api/v1/cookbooks"

        category_string = Chef::JSONCompat.to_json({ "category" => cookbook_category })

        http_resp = Chef::Knife::Core::CookbookSiteStreamingUploader.post(uri, user_id, user_secret_filename, {
          tarball: File.open(cookbook_filename),
          cookbook: category_string,
        })

        res = Chef::JSONCompat.from_json(http_resp.body)
        if http_resp.code.to_i != 201
          if res["error_messages"]
            if /Version already exists/.match?(res["error_messages"][0])
              ui.error "The same version of this cookbook already exists on Supermarket."
              exit(1)
            else
              ui.error (res["error_messages"][0]).to_s
              exit(1)
            end
          else
            ui.error "Unknown error while sharing cookbook"
            ui.error "Server response: #{http_resp.body}"
            exit(1)
          end
        end
        res
      end

      def tar_cmd
        unless @tar_cmd
          @tar_cmd = "tar"
          begin
            # Unix and Mac only - prefer gnutar
            if shell_out("which gnutar").exitstatus.equal?(0)
              @tar_cmd = "gnutar"
            end
          rescue Errno::ENOENT
          end
        end
        @tar_cmd
      end
    end
  end
end
