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

package "emacs" do
  version '22.1-0ubuntu10'
  action :install
end

file "/tmp/foo" do
  owner    "adam"
  mode     0644
  action   :create
  notifies :delete, resources(:file => "/tmp/glen"), :delayed
end

remote_file "/tmp/the_park.txt" do
  owner "adam"
  mode 0644
  source "the_park.txt"
  action :create
end

remote_directory "/tmp/remote_test" do
  owner "adam"
  mode 0755
  source "remote_test"
  files_owner "root"
  files_group(node[:operatingsystem] == "Debian" ? "root" : "wheel")
  files_mode 0644
  files_backup false
end

template "/tmp/foo-template" do
  owner    "adam"
  mode     0644
  source "monkey.erb"
  variables({
    :one => 'two',
    :el_che => 'rhymefest',
    :white => {
      :stripes => "are the best",
      :at => "the sleazy rock thing"
    },
  })
end

link "/tmp/foo" do
  link_type   :symbolic
  target_file "/tmp/xmen"
end 

# 0.upto(1000) do |n|
#   file "/tmp/somefile#{n}" do
#     owner  "adam"
#     mode   0644
#     action :create
#   end
# end

directory "/tmp/home" do
  owner "root"
  mode 0755
  action :create
end

search(:user, "*") do |u|
  directory "/tmp/home/#{u[:name]}" do
    if u[:name] == "nobody" && @node[:operatingsystem] == "Darwin"
      owner "root"
    else
      owner "#{u[:name]}"
    end
    mode 0755
    action :create
  end
end
