remote_directory "/srv/gems" do
  owner "www-data"
  mode 0755
  source "packages"
  files_owner "www-data"
  files_group "www-data"
  files_mode 0644
end
