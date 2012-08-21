name "chef-pedant"
version "osc"

dependencies ["ruby",
              "bundler",
              "rsync"]

# TODO: use the public git:// uri once this repo is public
source :git => "git@github.com:opscode/chef-pedant"

relative_path "chef-pedant"

build do
  bundle "install --path=#{install_dir}/embedded/service/gem"
  command "mkdir -p #{install_dir}/embedded/service/chef-pedant"
  command "#{install_dir}/embedded/bin/rsync -a --delete --exclude=.git/*** --exclude=.gitignore ./ #{install_dir}/embedded/service/chef-pedant/"
end
