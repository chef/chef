hab_sup 'tester' do
  license 'accept'
  bldr_url 'https://willem.habitat.sh'
  listen_http '0.0.0.0:9999'
  listen_gossip '0.0.0.0:9998'
  toml_config true
end

ruby_block 'wait-for-sup-default-startup' do
  block do
    raise unless system('hab sup status')
  end
  retries 30
  retry_delay 1
end
