
# Should never be executed, see comment below
execute("echo should-not-execute")

execute("echo foo") do
  # refers to the resource below, but there is an intentional typo
  # expected behavior is for the reference to be resolved *before*
  # Chef starts converging resources, so that the above execute
  # resource is never called.
  # Also, the error message should be helpful.
  notifies(:create, "file[#{node[:tmpdir]}/notified_file.txt]")
end

file "#{node[:tmpdir]}/not-notified_file.txt" do
  action :nothing
end
