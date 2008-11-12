web_server "monchichi" do
  one "something"
  two "something else"
end

runit_service "bobo" do
  directory "monkey"
  downif "/bin/false is true"
  templatedir "something"
end

define :runit_service, :directory => "/etc/sv", :downif => "/bin/false", :templatedir => nil do  
  include_recipe "runit"
  
  validate(
    params,
    {
      :directory => { :required => true },
      :downif    => { :required => true },
      :templatedir => { :required => false },
    }
  )
  
  file "#{param[:directory]}-#{param[:name]}" do
    path    "#{param[:directory]}/#{param[:name]}"
    insure  "directory"
    owner   "root"
    group   "root"
    mode    0755  
  end

  file "#{param[:directory]}/#{param[:name]}/log" do
    insure  "directory"
    owner  "root"
    group  "root"
    mode  0755
  end

  file "#{param[:directory]}/#{param[:name]}/log/main" do
    insure  "directory"
    owner  "root"
    group  "root"
    mode  0755
  end

  symlink "/etc/init.d/#{param[:name]}" do
    sv_dir = case node[:lsbdistid]
                  when 'CentOS': "/usr/local/bin/sv"
                  else: "/usr/bin/sv"
              end
    source_file = sv_dir
  end

  symlink "/var/service/#{param[:name]}" do
    source_file "#{param[:directory]}/#{param[:name]}"
  end
  
  service "#{param[:name]}" do
    supports :status => true, :restart => true 
  end

  template_file "#{param[:directory]}/#{param[:name]}/log/run" do
    content  "#{param[:templatedir]}/log-run.erb"
    owner    "root"
    group    "root"
    mode     755
    notifies resource("service[#{param[:name]}]")
  end

  template_file "#{param[:directory]}/#{param[:name]}/run" do
    content  "#{param[:templatedir]}/run.erb"
    owner    root
    group    root
    mode     755
    notifies resource("service[#{param[:name]}]")   
  end

  exec "#{param[:name]}-down" do
    command      "/etc/init.d/#{param[:name]} down"
    only_if      "#{downif}"
  end
end
