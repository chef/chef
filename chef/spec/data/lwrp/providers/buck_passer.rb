action :pass_buck do
  lwrp_foo :twiddled_thumbs do
    action :twiddle_thumbs
    provider :lwrp_thumb_twiddler
  end
end
