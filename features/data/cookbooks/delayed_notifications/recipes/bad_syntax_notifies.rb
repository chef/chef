
# Should never be executed, see comment below
execute("echo should-not-execute")

execute("echo foo") do
  # refers to the resource below but the syntax is wrong
  # expected behavior is for the reference to be resolved later
  # and the notification to work correctly
  notifies(:create, /file\[.*notified_file\.txt\]/) #regex isn't a valid argument here
end

file "#{node[:tmpdir]}/notified_file.txt" do
  action :nothing
end
