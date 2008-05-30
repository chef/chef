Merb::Config.use do |c|
  c[:session_store] = "memory"
end


class Hash
  
  def with( opts )
    self.merge(opts)
  end
  
  def without(*args)
    self.dup.delete_if{ |k,v| args.include?(k)}
  end
  
end