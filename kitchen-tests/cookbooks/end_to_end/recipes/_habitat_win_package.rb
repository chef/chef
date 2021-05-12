hab_install 'default' do
  license 'accept'
end

hab_package 'skylerto/splunkforwarder' do
  version '7.0.3/20180418161444'
end
