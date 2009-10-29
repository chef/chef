Merb.logger.info("Loaded PRODUCTION Environment...")
Merb::Config.use { |c|
  c[:exception_details] = false
  c[:reload_classes] = false
  c[:log_auto_flush] = true
  c[:log_level] = Chef::Config[:log_level]
  c[:log_stream] = Chef::Config[:log_location]
  # or redirect logger using IO handle
  # c[:log_stream] = STDOUT
}
