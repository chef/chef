class TopCookbooks < Chef::Resource
  resource_name :top_cookbooks

  property :command, String, name_property: true

  action :run do
    cookbook_kitchen "#{command} docker" do
    end

    cookbook_kitchen "#{command} git" do
    end

    cookbook_kitchen "#{command} learn-the-basics-ubuntu" do
      repository "learn-chef/learn-chef-acceptance"
      cookbook_relative_dir "cookbooks/learn-the-basics-ubuntu"
    end

    # cookbook_kitchen "#{command} learn-the-basics-windows" do
    #   repository "learn-chef/learn-chef-acceptance"
    #   cookbook_relative_dir "cookbooks/learn-the-basics-windows"
    # end

    # cookbook_kitchen "#{command} powershell" do
    # end

    # cookbook_kitchen "#{command} iis" do
    # end

    # cookbook_kitchen "#{command} sql_server" do
    # end

    # cookbook_kitchen "#{command} winbox" do
    #   repository "adamedx/winbox"
    # end

    # Temporarily disabling windows and chocolatey to eliminate
    # transient errors on the builders
    # cookbook_kitchen "#{command} windows" do
    # end

    # cookbook_kitchen "#{command} chocolatey" do
    #   repository "chocolatey/chocolatey-cookbook"
    # end
  end
end
