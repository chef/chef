powershell_package "PSReadline"

powershell_package "multi package install" do
  package_name %w{PSReadline chocolatey}
end

powershell_package "remove all packages" do
  package_name %w{PSReadline chocolatey}
  action :remove
end
