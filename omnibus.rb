
Omnibus.configure do |o|
  # o.s3_access_key   = "something"
  # o.s3_secret_key   = "something"
  #o.s3_bucket       = ""
  o.use_s3_caching  = false 
end

