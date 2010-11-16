execute("echo foo") do
  # refers to the resource below, which isn't defined yet.
  # expected behavior is for the reference to be resolved later
  # and the notification to work correctly
  notifies(:create, "file[#{node[:tmpdir]}/notified_file.txt]")
end

file "#{node[:tmpdir]}/notified_file.txt" do
  action :nothing
end
