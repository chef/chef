bork

list_of_users = []
list_of_users << { :user => "aj", :uid => 2000, :gid => 110, :home => "/tmp/home/aj", :comment => "AJ Christensen", :shell => "/bin/bash" }.to_mash
list_of_users << { :user => "adam", :uid => 2001, :gid => 110, :home => "/tmp/home/adam", :comment => "Adam Jacobs", :shell => "/bin/zsh" }.to_mash

list_of_users.each do |u|
  u.each { |k,v| Chef::Log.info("#{k}: #{v}") }
  user "#{u['user']}-test" do
    uid u['uid']
    gid u['gid']
    home u['home']
    shell u['shell']
    comment u['comment']
    shell u['shell']
    action [ :create, :lock ]
  end
end

execute "write-foolio" do
  command <<-EOH
    echo 'monkeypants #{node[:ipaddress]} #{node[:friends]}' > /tmp/foolio
  EOH
  user "daemon"
end

script "monkeylikesit" do
  code %q{
print "Woot!\n";
open(FILE, ">", "/tmp/monkeylikesit") or die "Cannot open monkeylikesit";
print FILE "You have some interesting hobbies #{node[:ipaddress]}";
close(FILE);
}
  interpreter "perl"
end

perl "foobar" do
  code %q{
print "Woot!\n";    
  }
end

unless @node[:operatingsystem] == "Ubuntu" or @node['operatingsystem'] == "Darwin"
  package "emacs"

  package "emacs" do
    action :remove
  end

  package "emacs" do
    version "22.1-0ubuntu10"
    action :install
  end

  package "emacs" do
    action :upgrade
  end

  package "emacs" do
    action :purge
  end
end

#package "ruby-djbdns" do
#  action [ :install, :remove, :upgrade, :purge ]
#  provider Chef::Provider::Package::Rubygems
#end

#gem_package "ruby-djbdns" do
#  action [ :install, :remove, :upgrade, :purge ]
#end

file "/tmp/glen" do
  owner "aj-test"
  mode 0644
  action :create
end

file "/tmp/foo" do
  owner    "adam-test"
  mode     0644
  action   :create
  notifies :delete, resources(:file => "/tmp/glen"), :delayed
end

remote_file "/tmp/the_park.txt" do
  owner "adam-test"
  mode 0644
  source "the_park.txt"
  action :create
end

remote_directory "/tmp/remote_test" do
  owner "adam-test"
  mode 0755
  source "remote_test"
  files_owner "root"
  files_group(@node['operatingsystem'] == "Ubuntu" ? "admin" : "wheel")
  files_mode 0644
  files_backup false
end

template "/tmp/foo-template" do
  owner    "adam-test"
  mode     0644
  source "monkey.erb"
  variables({
    :one => 'two',
    :el_che => 'rhymefest',
    :white => {
      :stripes => "are the best",
      :at => "the sleazy rock thing",
    }
  })
end

link "/tmp/foo" do
  link_type   :symbolic
  target_file "/tmp/xmen"
end 

directory "/tmp/lots_of_files/" do
  owner "adam-test"
  mode 0755
  action :create
end

1000.times do |n|
  file "/tmp/lots_of_files/somefile#{n}" do
    owner  "adam-test"
    mode   0644
    action :create
  end
end

directory "/tmp/home" do
  owner "root"
  mode 0755
  action :create
end

search(:user, "*") do |u|
  directory "/tmp/home/#{u['name']}" do
    if u['name'] == "nobody" && @node[:operatingsystem] == "Darwin"
      owner "root"
    else
      owner "#{u['name']}"
    end
    mode 0755
    action :create
  end
end

monkey "snoopy" do
  eats "vegetables"
end

monkey "snack"

user "katie" do
  uid 9999
  gid 100
  home "/tmp/home/katie"
  shell "/bin/bash"
  comment "Katie Bethell"
  action :create
end
 
user "katie" do
  gid 101
  action :modify
end

user "katie" do
  shell "/home/katie"
  action :manage
end

user "katie" do
  action [ :lock, :unlock, :remove ]
end

