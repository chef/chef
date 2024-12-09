registry_key 'HKEY_LOCAL_MACHINE\System\RegTest' do
  values [{
    name: 'test',
    type: :dword,
    data: '1',
    }]
  action :create
  recursive true
end

