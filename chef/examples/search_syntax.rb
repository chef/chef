search(:users, "allowed:#{node[:hostname]} or allowed:#{node[:tags]}") do |u|
  user "#{u['username']}" do
    uid "#{u['uid']}"
    gid "#{u['gid']}"
    username "#{u['username']}"
    homedir "#{u['homedir']}"
    action :create
  end
end

