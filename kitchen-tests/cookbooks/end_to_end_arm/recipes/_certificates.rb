#
# Cookbook:: end_to_end_arm
# Recipe:: _certificates
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#
# windows_certificate needs an actual certificate file on disk. Rather than
# relying on a prebuilt file shipped from the cookbook's files/ directory
# (the failure mode seen in cookbooks/end_to_end), generate a throwaway
# self-signed certificate locally first, then install it.
#

cert_dir = "C:\\chef_arm_test\\certs"
cert_password = "P@ssw0rdForTesting123!"
pfx_path = "#{cert_dir}\\chef-arm-test.pfx"
cer_path = "#{cert_dir}\\chef-arm-test.cer"

directory cert_dir do
  recursive true
end

powershell_script "generate self-signed test certificate" do
  code <<-EOH
    $cert = New-SelfSignedCertificate -DnsName "chef-arm-test.local" -CertStoreLocation "Cert:\\LocalMachine\\My" -NotAfter (Get-Date).AddYears(1)
    $securePassword = ConvertTo-SecureString -String "#{cert_password}" -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath "#{pfx_path}" -Password $securePassword | Out-Null
    Export-Certificate -Cert $cert -FilePath "#{cer_path}" | Out-Null
    Remove-Item -Path "Cert:\\LocalMachine\\My\\$($cert.Thumbprint)" -Force
  EOH
  not_if { ::File.exist?(pfx_path) && ::File.exist?(cer_path) }
end

windows_certificate pfx_path do
  pfx_password cert_password
  action :create
  user_store true
  store_name "MY"
end

windows_certificate cer_path do
  store_name "ROOT"
end
