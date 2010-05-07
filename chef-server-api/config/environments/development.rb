Merb::Config.use do |c|
  c[:exception_details] = true
  c[:reload_classes]    = true 
end

Merb.logger.level = :debug