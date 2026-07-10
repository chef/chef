#
# Cookbook:: end_to_end
# Recipe:: _template_partial_paths
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

template "/tmp/chef-template-partial-paths" do
  source "template_partial_paths.erb"
  variables(
    paths: ["/etc/chef/client.rb", "/etc/chef/client.pem"]
  )
end
