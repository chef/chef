source "https://rubygems.org"

gem "knife", path: "."

group(:development, :test) do
  gem "cheffish", ">= 14" # testing only , but why didn't this need to explicit in chef?
  gem "webmock"
  gem "crack", "< 0.4.6" # due to https://github.com/jnunemaker/crack/pull/75
  gem "rake", ">= 12.3.3"
  gem "rspec"
  gem "chef-bin", path: "../chef-bin"
end

group(:omnibus_package, :pry) do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
end

group(:chefstyle) do
  gem "chefstyle", git: "https://github.com/chef/chefstyle.git", branch: "main"
end

gem "ohai", git: "https://github.com/chef/ohai.git", branch: "main"
gem "chef", path: ".."
gem "chef-utils", path: File.expand_path("../chef-utils", __dir__) if File.exist?(File.expand_path("../chef-utils", __dir__))
gem "chef-config", path: File.expand_path("../chef-config", __dir__) if File.exist?(File.expand_path("../chef-config", __dir__))
