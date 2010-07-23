Chef::Log.info("")
Chef::Log.info("*" * 80)
Chef::Log.info("*   Starting Chef Server in Development Mode.")
Chef::Log.info("*   Start the server with `-e production` for normal use")
Chef::Log.info("*" * 80)
Chef::Log.info("")

Merb::Config.use do |c|
  c[:exception_details] = true
  c[:reload_classes]    = true
  c[:log_level]         = :debug
end
