1000.times do |i|
  registry_key "HKEY_LOCAL_MACHINE\\SOFTWARE\\Notepad\\Pad{i}" do
    values [{
      name: "AThing",
      type: :string,
      data: "NaN"*1400
    }]
    action :create
    recursive true
  end
end

registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Notepad\Pad' do
  values [{
    name: 'ProtectionMode',
    type: :dword,
    data: '1'
  }]
  action :create
  recursive true
end
