Merb.logger.info("Loaded TEST Environment...")
Merb::Config.use { |c|
  c[:testing] = true
  c[:exception_details] = true
  c[:log_auto_flush ] = true
}