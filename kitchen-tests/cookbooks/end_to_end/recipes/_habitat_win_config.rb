hab_sup 'default' do
  license 'accept'
end

ruby_block 'wait-for-sup-default-startup' do
  block do
    raise unless system('hab sup status')
  end
  retries 30
  retry_delay 1
end

hab_service 'skylerto/splunkforwarder'

hab_config 'splunkforwarder.default' do
  config(
    directories: {
      path: [
        'C:/hab/pkgs/.../*.log',
      ],
    }
  )
end
