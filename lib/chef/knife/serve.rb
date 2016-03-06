require "chef/knife"
require "chef/local_mode"

class Chef
  class Knife
    class Serve < Knife

      banner "knife serve (options)"

      option :repo_mode,
        :long => "--repo-mode MODE",
        :description => "Specifies the local repository layout. Values: static (only environments/roles/data_bags/cookbooks), everything (includes nodes/clients/users), hosted_everything (includes acls/groups/etc. for Enterprise/Hosted Chef). Default: everything/hosted_everything"

      option :chef_repo_path,
        :long => "--chef-repo-path PATH",
        :description => "Overrides the location of chef repo. Default is specified by chef_repo_path in the config"

      option :chef_zero_host,
        :long => "--chef-zero-host IP",
        :description => "Overrides the host upon which chef-zero listens. Default is 127.0.0.1."

      def configure_chef
        super
        Chef::Config.local_mode = true
        Chef::Config[:repo_mode] = config[:repo_mode] if config[:repo_mode]

        # --chef-repo-path forcibly overrides all other paths
        if config[:chef_repo_path]
          Chef::Config.chef_repo_path = config[:chef_repo_path]
          %w{acl client cookbook container data_bag environment group node role user}.each do |variable_name|
            Chef::Config.delete("#{variable_name}_path".to_sym)
          end
        end
      end

      def run
        server = Chef::LocalMode.chef_zero_server
        begin
          output "Serving files from:\n#{Chef::LocalMode.chef_fs.fs_description}"
          server.stop
          server.start(stdout) # to print header
        ensure
          server.stop
        end
      end
    end
  end
end
