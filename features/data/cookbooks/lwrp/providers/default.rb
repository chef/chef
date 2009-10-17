action :print_message do
  puts new_resource.message
end

action :touch_file do
  file "#{node[:tmpdir]}/#{new_resource.filename}" do
    action :create
  end
end
