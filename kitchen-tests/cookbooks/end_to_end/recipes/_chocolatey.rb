#
# Cookbook:: end_to_end
# Recipe:: chocolatey
#

chocolatey_installer 'latest' do
  action :install
end

chocolate_package 'install non-existent package' do
  package_name 'gvim'
end

chocolate_package 'install vim' do
  package_name 'vim'
end

chocolate_package 'install the_silver_searcher' do
  package_name 'ag'
end