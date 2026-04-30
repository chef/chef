require "fileutils"

name "remove-vulnerable-msys-artifacts"

license :project_license
skip_transitive_dependency_licensing true

build do
  block "Removing unused MSYS OpenSSL binary" do
    next unless windows?

    msys_openssl = "#{install_dir}/embedded/msys64/usr/bin/openssl.exe"

    if File.exist?(msys_openssl)
      puts "Deleting #{msys_openssl}"
      FileUtils.rm_f(msys_openssl)
    else
      puts "MSYS OpenSSL binary not found at #{msys_openssl}. Skipping."
    end
  end
end
