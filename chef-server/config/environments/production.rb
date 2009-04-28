Merb.logger.info("Loaded PRODUCTION Environment...")
Merb::Config.use { |c|
  c[:exception_details] = false
  c[:reload_classes] = false
  c[:log_level] = :error
  c[:log_stream] = Chef::Config[:log_location]
  c[:log_file]   = nil  
  # or redirect logger using IO handle
  # c[:log_stream] = STDOUT
}
