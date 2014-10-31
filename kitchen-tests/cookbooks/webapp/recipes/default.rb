#
# Cookbook Name:: webapp
# Recipe:: default
#
# Copyright (C) 2014
#

include_recipe "apache2"
include_recipe "database::mysql"
include_recipe "php"

creds = Hash.new
%w(mysql webapp).each do |item_name|
  creds[item_name] = data_bag_item('passwords', item_name)
end

web_app "webapp" do
  server_name 'localhost'
  server_aliases [node['fqdn'], node['hostname'], 'localhost.localdomain']
  docroot node['webapp']['path']
  cookbook 'apache2'
end

mysql_service "default" do
  server_root_password creds['mysql']['server_root_password']
  server_repl_password creds['mysql']['server_repl_password']
end

mysql_database node['webapp']['database'] do
  connection ({
    :host => 'localhost',
    :username => 'root',
    :password => creds['mysql']['server_root_password']
  })
  action :create
end

mysql_database_user node['webapp']['db_username'] do
  connection ({
    :host => 'localhost',
    :username => 'root',
    :password => creds['mysql']['server_root_password']
  })
  password creds['webapp']['db_password']
  database_name node['webapp']['database']
  privileges [:select, :update, :insert, :create, :delete]
  action :grant
end

directory node['webapp']['path'] do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

template "#{node['webapp']['path']}/index.html" do
  source 'index.html.erb'
end

template "#{node['webapp']['path']}/index.php" do
  source 'index.php.erb'
end
