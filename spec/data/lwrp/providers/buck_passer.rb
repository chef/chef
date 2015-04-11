provides :buck_passer

action :pass_buck do
  lwrp_foo :prepared_thumbs do
    action :prepare_thumbs
    provider :lwrp_thumb_twiddler
  end
  lwrp_foo :twiddled_thumbs do
    action :twiddle_thumbs
    provider :lwrp_thumb_twiddler
  end
end
