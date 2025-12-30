only_if("Habitat and cacerts must be present on Linux") do
  os.linux? && file("/hab/bin/hab").exist? && !command("bash -lc 'ls -1 /hab/pkgs/core/cacerts/*/ssl/certs/cacert.pem 2>/dev/null' ").stdout.strip.empty?
end

pem_path = command("bash -lc 'ls -1 /hab/pkgs/core/cacerts/*/ssl/certs/cacert.pem 2>/dev/null | head -n1'").stdout.strip

describe("chef_client_hab_ca_cert appended bundle on Linux") do
  describe file(pem_path) do
    it { should exist }
    its("content") { should match(/Cert Bundle - kitchen-test/) }
    its("content") { should match(/-----BEGIN CERTIFICATE-----/) }
    its("content") { should match(/-----END CERTIFICATE-----/) }
  end
end
