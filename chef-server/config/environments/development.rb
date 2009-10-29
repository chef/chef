Merb.logger.info("Loaded DEVELOPMENT Environment...")
Merb::Config.use { |c|
  c[:exception_details] = true
  c[:reload_templates] = true
  c[:reload_classes] = true
  c[:reload_time] = 0.5
  c[:log_auto_flush ] = true
  c[:log_level] = :debug
  c[:log_stream] = Chef::Config[:log_location]
  c[:log_file]   = nil
  # Or redirect logging into a file:
  # c[:log_file]  = Merb.root / "log" / "development.log"
}
