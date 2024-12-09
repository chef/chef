registry_key 'HKEY_LOCAL_MACHINE\System\RegTest' do
  values [{
    name: 'test',
    type: :string,
    data: SecureRandom.base64(2**16)
    }]
  action :create
  recursive true
end

