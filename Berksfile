source 'https://api.berkshelf.com'

cookbook 'omnibus'
cookbook 'docker', github: 'tduffield/chef-docker'

# Uncomment to use the latest version of the Omnibus cookbook from GitHub
# cookbook 'omnibus', github: 'opscode-cookbooks/omnibus'

group :integration do
  cookbook 'apt',      '~> 2.3'
  cookbook 'freebsd',  '~> 0.1'
  cookbook 'yum-epel', '~> 0.3'
end
