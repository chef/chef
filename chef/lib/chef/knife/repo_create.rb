require 'chef/knife'
require 'fileutils'

class Chef
  class Knife
    class RepoCreate < Knife

      banner "knife repo create REPO"

      def run
        self.config = Chef::Config.merge! config

        if @name_args.length < 1
          show_usage
          ui.fatal "You must specify a repo name"
          exit 1
        end

        repo_name = @name_args.first
        create_repo repo_name
      end

      def create_repo(repo_name)
        msg "** Creating repo #{repo_name}"
        FileUtils.mkdir_p "#{repo_name}"

        %w[ certificates config cookbooks data_bags environments roles ].each do |dir|
          FileUtils.mkdir_p "#{File.join repo_name, dir}"
        end
      end
    end
  end
end
