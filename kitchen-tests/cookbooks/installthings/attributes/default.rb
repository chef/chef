case node['platform_family']
when "debian"
  default['installthings']['push_client_url'] =
    'https://opscode-private-chef.s3.amazonaws.com/ubuntu/12.04/x86_64/opscode-push-jobs-client_1.1.5-1_amd64.deb'
when "rhel"
  default['installthings']['push_client_url'] =
    'https://opscode-private-chef.s3.amazonaws.com/el/6/x86_64/opscode-push-jobs-client-1.1.5-1.el6.x86_64.rpm'
end
