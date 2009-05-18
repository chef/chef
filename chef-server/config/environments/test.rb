Merb.logger.info("Loaded TEST Environment...")
Merb::Config.use { |c|
  c[:testing]           = true
  c[:exception_details] = true
  c[:log_auto_flush ]   = true
  
  # log less in testing environment
  c[:log_level]         = :error
  c[:log_stream] = Chef::Config[:log_location]
  c[:log_file]   = nil
  #c[:log_file]  = Merb.root / "log" / "test.log"
  # or redirect logger using IO handle
}
