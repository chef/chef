class TopCookbooks < Chef::Resource
  resource_name :top_cookbooks

  property :command, String, name_property: true

  action :run do
    cookbook_kitchen "#{command} git" do
    end

    cookbook_kitchen "#{command} learn-the-basics-ubuntu" do
      repository "learn-chef/learn-chef-acceptance"
      cookbook_relative_dir "cookbooks/learn-the-basics-ubuntu"
    end
  end
end
