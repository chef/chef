only_if("Habitat and cacerts must be present on Windows") do
  os.windows? && file("C:/ProgramData/Habitat/hab.exe").exist? && !powershell("Get-ChildItem -Path C:/hab/pkgs/core/cacerts/*/ssl/certs/cacert.pem -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1").stdout.strip.empty?
end

pem_path = powershell("(Get-ChildItem -Path C:/hab/pkgs/core/cacerts/*/ssl/certs/cacert.pem -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)").stdout.strip

describe("chef_client_hab_ca_cert appended bundle on Windows") do
  describe file(pem_path) do
    it { should exist }
    its("content") { should match(/Cert Bundle - kitchen-test/) }
    its("content") { should match(/-----BEGIN CERTIFICATE-----/) }
    its("content") { should match(/-----END CERTIFICATE-----/) }
  end
end
