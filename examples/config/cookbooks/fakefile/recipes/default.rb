
file "/tmp/foo" do
  owner    "adam"
  mode     0644
  action   :create
  notifies :delete, resources(:file => "/tmp/glen"), :delayed
end

template "/tmp/foo-template" do
  owner    "adam"
  mode     0644
  template "monkey.erb"
  variables({
    :one => 'two',
    :el_che => 'rhymefest',
    :white => {
      :stripes => "are the best",
      :at => "the sleazy rock thing"
    }
  })
end

link "/tmp/foo" do
  link_type   :symbolic
  target_file "/tmp/xmen"
end 

0.upto(1000) do |n|
  file "/tmp/somefile#{n}" do
    owner  "adam"
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
