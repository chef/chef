Chef::Log.info("")
Chef::Log.info("*" * 80)
Chef::Log.info("*   Starting Chef Server Web UI in Development Mode.")
Chef::Log.info("*   Start the server with `-e production` for normal use")
Chef::Log.info("*" * 80)
Chef::Log.info("")

Merb::Config.use do |c|
  c[:exception_details]  = true
  c[:reload_classes]     = true
  c[:reload_templates]   = true
end
